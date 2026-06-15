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

class ScriptExecutionParser {
  static final RegExp _serverBashRegExp = RegExp(r'^#bash\s+server\b', caseSensitive: false);
  static final RegExp _androidBashRegExp = RegExp(r'^#bash\b', caseSensitive: false);
  static final RegExp _endBashRegExp = RegExp(r'^#(endbash|end\s+bash|end|adb)\b', caseSensitive: false);

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
