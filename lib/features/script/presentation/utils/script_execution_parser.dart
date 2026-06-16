import '../../domain/entities/script_entity.dart';

abstract class ScriptExecutionBlock {}

class SingleCommandBlock extends ScriptExecutionBlock {
  final String command;
  SingleCommandBlock(this.command);
}

class BashScriptBlock extends ScriptExecutionBlock {
  final List<String> commands;
  BashScriptBlock(this.commands);
}

class ServerBashScriptBlock extends ScriptExecutionBlock {
  final List<String> commands;
  ServerBashScriptBlock(this.commands);
}

class SubScriptCall {
  final String scriptName;
  final Map<String, String> params;
  SubScriptCall(this.scriptName, this.params);
}

class ScriptExecutionParser {
  static final RegExp _serverBashRegExp = RegExp(r'^#bash\s+server\b', caseSensitive: false);
  static final RegExp _androidBashRegExp = RegExp(r'^#bash\b', caseSensitive: false);
  static final RegExp _endBashRegExp = RegExp(r'^#(endbash|end\s+bash|end|adb)\b', caseSensitive: false);

  /// Phân tích dòng gọi script con để trích xuất tên script và các tham số
  static SubScriptCall _parseSubScriptCall(String line) {
    final trimmed = line.trim();
    final content = trimmed.substring('#run-script '.length).trim();
    final parts = content.split(RegExp(r'\s+'));
    
    final Map<String, String> params = {};
    int paramStartIndex = parts.length;
    
    for (int i = parts.length - 1; i >= 0; i--) {
      final part = parts[i];
      if (part.contains('=')) {
        final eqIndex = part.indexOf('=');
        final key = part.substring(0, eqIndex).trim();
        final value = part.substring(eqIndex + 1).trim();
        if (key.isNotEmpty) {
          params[key] = value;
          paramStartIndex = i;
        } else {
          break;
        }
      } else {
        break;
      }
    }
    
    final scriptName = parts.sublist(0, paramStartIndex).join(' ').trim();
    return SubScriptCall(scriptName, params);
  }

  /// Kiểm tra tính hợp lệ của các tham số truyền vào so với các placeholder trong script con.
  static void _validateParams(List<String> subCommands, Map<String, String> params, String subScriptName) {
    final combinedCommands = subCommands.join('\n');

    params.forEach((key, value) {
      bool isUsed = false;
      if (key == 'file') {
        isUsed = combinedCommands.contains('{file}');
      } else if (key == 'input') {
        isUsed = combinedCommands.contains('{input}') || combinedCommands.contains('{input:input}');
      } else {
        isUsed = combinedCommands.contains('{input:$key}');
      }

      if (!isUsed) {
        throw Exception('Script con "$subScriptName" không sử dụng tham số "$key". Vui lòng kiểm tra lại tên tham số.');
      }
    });
  }

  /// Áp dụng các tham số truyền vào để thay thế các placeholder tương ứng trong lệnh của script con
  static List<String> _applyParams(List<String> commands, Map<String, String> params) {
    final List<String> result = [];
    for (final cmd in commands) {
      var updatedCmd = cmd;
      params.forEach((key, value) {
        if (key == 'file') {
          updatedCmd = updatedCmd.replaceAll('{file}', value);
        } else if (key == 'input') {
          updatedCmd = updatedCmd.replaceAll('{input}', value);
          updatedCmd = updatedCmd.replaceAll('{input:input}', value);
        } else {
          updatedCmd = updatedCmd.replaceAll('{input:$key}', value);
        }
      });
      result.add(updatedCmd);
    }
    return result;
  }

  /// Đệ quy làm phẳng danh sách lệnh bằng cách thay thế các tag `#run-script <tên>` bằng nội dung lệnh của script con.
  /// Phát hiện và ném lỗi nếu có vòng lặp vô hạn hoặc thiếu script con.
  static List<String> flatten(
    List<String> commands,
    List<ScriptEntity> allScripts, {
    Set<String>? visitedScriptNames,
  }) {
    visitedScriptNames ??= {};
    final List<String> result = [];

    for (final cmd in commands) {
      final trimmed = cmd.trim();
      if (trimmed.startsWith('#run-script ')) {
        final call = _parseSubScriptCall(trimmed);
        if (call.scriptName.isEmpty) {
          result.add(cmd);
          continue;
        }

        if (visitedScriptNames.contains(call.scriptName)) {
          throw Exception('Phát hiện vòng lặp vô hạn gọi script con: ${call.scriptName}');
        }

        // Tìm script con theo tên
        final subScript = allScripts.firstWhere(
          (s) {
            return s.name.trim().toLowerCase() == call.scriptName.toLowerCase();
          },
          orElse: () => throw Exception('Không tìm thấy script con có tên: "${call.scriptName}"'),
        );

        // Kiểm tra tính hợp lệ của tham số truyền vào
        _validateParams(subScript.commands, call.params, call.scriptName);

        // Áp dụng các tham số truyền vào cho các lệnh của script con
        final parameterizedCommands = _applyParams(subScript.commands, call.params);

        // Đệ quy làm phẳng tiếp tục
        final subFlat = flatten(
          parameterizedCommands,
          allScripts,
          visitedScriptNames: {...visitedScriptNames, call.scriptName},
        );
        result.addAll(subFlat);
      } else {
        result.add(cmd);
      }
    }
    return result;
  }


  /// Phân tích danh sách lệnh thô đã nội suy thành các khối thực thi (Single vs Bash Batch vs Server Bash Batch)
  static List<ScriptExecutionBlock> parse(List<String> processedCommands) {
    final List<ScriptExecutionBlock> blocks = [];
    List<String>? currentBashCommands;
    List<String>? currentServerBashCommands;

    for (final command in processedCommands) {
      var trimmed = command.trim();
      
      // Nếu dòng bắt đầu bằng $
      if (trimmed.startsWith('\$')) {
        final rest = trimmed.substring(1).trim();
        // Nếu không ở trong khối bash nào, HOẶC nếu phần còn lại bắt đầu bằng '#' (nhãn có $ thừa ở đầu)
        if ((currentBashCommands == null && currentServerBashCommands == null) || rest.startsWith('#')) {
          trimmed = rest;
        }
      }


      // Nhãn bắt đầu khối Bash Server
      if (_serverBashRegExp.hasMatch(trimmed)) {
        if (currentBashCommands != null) {
          blocks.add(BashScriptBlock(currentBashCommands));
          currentBashCommands = null;
        }
        if (currentServerBashCommands != null) {
          blocks.add(ServerBashScriptBlock(currentServerBashCommands));
        }
        currentServerBashCommands = [];
      }
      // Nhãn bắt đầu khối Bash Android
      else if (_androidBashRegExp.hasMatch(trimmed)) {
        if (currentServerBashCommands != null) {
          blocks.add(ServerBashScriptBlock(currentServerBashCommands));
          currentServerBashCommands = null;
        }
        if (currentBashCommands != null) {
          blocks.add(BashScriptBlock(currentBashCommands));
        }
        currentBashCommands = [];
      } 
      // Nhãn kết thúc khối Bash
      else if (_endBashRegExp.hasMatch(trimmed)) {
        if (currentBashCommands != null) {
          blocks.add(BashScriptBlock(currentBashCommands));
          currentBashCommands = null;
        }
        if (currentServerBashCommands != null) {
          blocks.add(ServerBashScriptBlock(currentServerBashCommands));
          currentServerBashCommands = null;
        }
      } 
      // Xử lý các lệnh thông thường
      else {
        if (currentBashCommands != null) {
          currentBashCommands.add(command);
        } else if (currentServerBashCommands != null) {
          currentServerBashCommands.add(command);
        } else {
          // Bỏ qua dòng trống hoặc dòng comment không phải nhãn
          if (trimmed.isEmpty || (trimmed.startsWith('#') && !_androidBashRegExp.hasMatch(trimmed))) {
            continue;
          }
          blocks.add(SingleCommandBlock(command));
        }
      }
    }

    if (currentBashCommands != null) {
      blocks.add(BashScriptBlock(currentBashCommands));
    }
    if (currentServerBashCommands != null) {
      blocks.add(ServerBashScriptBlock(currentServerBashCommands));
    }

    return blocks;
  }
}
