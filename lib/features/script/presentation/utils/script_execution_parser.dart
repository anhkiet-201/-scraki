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

class ClientImportCall {
  final String scriptName;
  final List<String> arguments;
  final String? exitCodeVariable;
  ClientImportCall(this.scriptName, this.arguments, {this.exitCodeVariable});
}

class ScriptEnvInfo {
  final bool hasServerBash;
  final bool hasAndroidBash;
  final bool hasSingleAndroidCommands;

  ScriptEnvInfo({
    required this.hasServerBash,
    required this.hasAndroidBash,
    required this.hasSingleAndroidCommands,
  });
}

class ScriptExecutionParser {
  static final RegExp _serverBashRegExp = RegExp(r'^#bash\s+server\b', caseSensitive: false);
  static final RegExp _androidBashRegExp = RegExp(r'^#bash\b', caseSensitive: false);
  static final RegExp _endBashRegExp = RegExp(r'^#(endbash|end\s+bash|end|adb)\b', caseSensitive: false);

  static ClientImportCall _parseClientImportCall(String line) {
    String? exitCodeVariable;
    String directive = line.trim();

    final assignRegExp = RegExp(r'^\$(\w+)\s*=?\s*(#import\s+client\s+.+)$', caseSensitive: false);
    final match = assignRegExp.firstMatch(directive);
    if (match != null) {
      exitCodeVariable = match.group(1);
      directive = match.group(2)!.trim();
    }

    final clientRegExp = RegExp(r'^#import\s+client\s+(.+)$', caseSensitive: false);
    final clientMatch = clientRegExp.firstMatch(directive);
    if (clientMatch == null) {
      return ClientImportCall('', [], exitCodeVariable: exitCodeVariable);
    }
    
    final content = clientMatch.group(1)!.trim();
    
    final regExp = RegExp(r"""[^\s"']*(?:"[^"]*"|'[^']*')[^\s"']*|[^\s]+""");
    final parts = regExp.allMatches(content).map((m) => m.group(0)!).toList();
    
    if (parts.isEmpty) {
      return ClientImportCall('', [], exitCodeVariable: exitCodeVariable);
    }
    
    final scriptName = _cleanQuotes(parts[0]);
    final arguments = parts.sublist(1);
    return ClientImportCall(scriptName, arguments, exitCodeVariable: exitCodeVariable);
  }

  static String _cleanQuotes(String s) {
    var trimmed = s.trim();
    if (trimmed.length >= 2) {
      if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
          (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
        return trimmed.substring(1, trimmed.length - 1).trim();
      }
    }
    return trimmed;
  }

  static String _normalizeArgument(String arg) {
    var trimmed = arg.trim();
    if (trimmed.isEmpty) return "''";
    
    // Loại bỏ cặp nháy kép hoặc nháy đơn ngoài cùng nếu có
    if (trimmed.length >= 2 &&
        ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
         (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
      trimmed = trimmed.substring(1, trimmed.length - 1);
    }
    
    // Bọc lại bằng nháy đơn để truyền an toàn qua adb shell
    return "'$trimmed'";
  }

  static ScriptEnvInfo _detectScriptEnvironments(List<String> commands) {
    bool hasServerBash = false;
    bool hasAndroidBash = false;
    bool hasSingleAndroidCommands = false;

    bool inBlock = false;

    for (final line in commands) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (_serverBashRegExp.hasMatch(trimmed)) {
        hasServerBash = true;
        inBlock = true;
      } else if (_androidBashRegExp.hasMatch(trimmed)) {
        hasAndroidBash = true;
        inBlock = true;
      } else if (_endBashRegExp.hasMatch(trimmed)) {
        inBlock = false;
      } else {
        if (!inBlock) {
          if (trimmed.startsWith('#') && !trimmed.startsWith('#import')) {
            continue;
          }
          hasSingleAndroidCommands = true;
        }
      }
    }

    return ScriptEnvInfo(
      hasServerBash: hasServerBash,
      hasAndroidBash: hasAndroidBash,
      hasSingleAndroidCommands: hasSingleAndroidCommands,
    );
  }

  /// Đệ quy làm phẳng danh sách lệnh bằng cách thay thế các tag `#import <tên>` bằng nội dung lệnh của script con.
  /// Phát hiện và ném lỗi nếu có vòng lặp vô hạn hoặc thiếu script con.
  static List<String> flatten(
    List<String> commands,
    List<ScriptEntity> allScripts, {
    Set<String>? visitedScriptNames,
  }) {
    visitedScriptNames ??= {};
    final List<String> result = [];

    bool isInServerBash = false;
    bool isInAndroidBash = false;

    for (final cmd in commands) {
      final trimmed = cmd.trim();

      // Theo dõi trạng thái khối môi trường hiện tại của script cha
      if (_serverBashRegExp.hasMatch(trimmed)) {
        isInServerBash = true;
        isInAndroidBash = false;
      } else if (_androidBashRegExp.hasMatch(trimmed)) {
        isInAndroidBash = true;
        isInServerBash = false;
      } else if (_endBashRegExp.hasMatch(trimmed)) {
        isInServerBash = false;
        isInAndroidBash = false;
      }

      final isClientImport = RegExp(r'^(?:\$\w+\s*=?\s*)?#import\s+client\s+', caseSensitive: false).hasMatch(trimmed);

      if (isClientImport) {
        if (!isInServerBash) {
          throw Exception('Chỉ thị "#import client" chỉ hợp lệ bên trong khối "#bash server"');
        }

        final call = _parseClientImportCall(trimmed);
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

        // Kiểm tra tương thích ngữ cảnh
        final info = _detectScriptEnvironments(subScript.commands);
        if (info.hasServerBash) {
          throw Exception('Không thể sử dụng "#import client" cho script con "${call.scriptName}" chứa mã PowerShell (#bash server).');
        }

        // Đệ quy làm phẳng tiếp tục
        var subFlat = flatten(
          subScript.commands,
          allScripts,
          visitedScriptNames: {...visitedScriptNames, call.scriptName},
        );

        // Loại bỏ các nhãn môi trường ở cấp ngoài cùng của script con
        subFlat = subFlat.where((line) {
          final t = line.trim();
          final isLabel = _serverBashRegExp.hasMatch(t) ||
                          _androidBashRegExp.hasMatch(t) ||
                          _endBashRegExp.hasMatch(t);
          return !isLabel;
        }).toList();

        // Tạo PowerShell wrapper
        final String adbCommand;
        if (call.arguments.isEmpty) {
          adbCommand = "'@ | adb -s {SERIAL} shell sh";
        } else {
          final normalizedArgs = call.arguments.map(_normalizeArgument).toList();
          adbCommand = "'@ | adb -s {SERIAL} shell \"sh -s ${normalizedArgs.join(' ')}\"";
        }

        final List<String> wrapper = [
          "@'",
          ...subFlat,
          adbCommand,
          if (call.exitCodeVariable != null) '\$${call.exitCodeVariable} = \$LASTEXITCODE',
        ];

        result.addAll(wrapper);
      } else if (trimmed.startsWith('#import ')) {
        final rawSubScriptName = trimmed.substring('#import '.length).trim();
        if (rawSubScriptName.isEmpty) {
          result.add(cmd);
          continue;
        }
        final subScriptName = _cleanQuotes(rawSubScriptName);

        if (visitedScriptNames.contains(subScriptName)) {
          throw Exception('Phát hiện vòng lặp vô hạn gọi script con: $subScriptName');
        }

        // Tìm script con theo tên
        final subScript = allScripts.firstWhere(
          (s) {
            return s.name.trim().toLowerCase() == subScriptName.toLowerCase();
          },
          orElse: () => throw Exception('Không tìm thấy script con có tên: "$subScriptName"'),
        );

        // Kiểm tra tương thích ngữ cảnh
        final info = _detectScriptEnvironments(subScript.commands);
        if (isInServerBash) {
          if (info.hasAndroidBash || info.hasSingleAndroidCommands) {
            throw Exception('Script con "$subScriptName" chứa các lệnh Android (Bash/Single) không thể import trực tiếp vào khối "#bash server" bằng "#import". Vui lòng sử dụng "#import client $subScriptName" để thực thi trên thiết bị.');
          }
        } else if (isInAndroidBash) {
          if (info.hasServerBash) {
            throw Exception('Không thể import script con "$subScriptName" chứa mã PowerShell (#bash server) vào môi trường Android Bash (#bash).');
          }
        }

        // Đệ quy làm phẳng tiếp tục
        var subFlat = flatten(
          subScript.commands,
          allScripts,
          visitedScriptNames: {...visitedScriptNames, subScriptName},
        );

        // Nếu đang ở trong một khối bash đang hoạt động của script cha,
        // loại bỏ các nhãn phân đoạn môi trường ở cấp ngoài cùng của script con.
        if (isInServerBash || isInAndroidBash) {
          subFlat = subFlat.where((line) {
            final t = line.trim();
            final isLabel = _serverBashRegExp.hasMatch(t) ||
                            _androidBashRegExp.hasMatch(t) ||
                            _endBashRegExp.hasMatch(t);
            return !isLabel;
          }).toList();
        }

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
