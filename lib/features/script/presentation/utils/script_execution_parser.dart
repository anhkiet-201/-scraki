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
  /// Phân tích danh sách lệnh thô đã nội suy thành các khối thực thi (Single vs Bash Batch vs Server Bash Batch)
  static List<ScriptExecutionBlock> parse(List<String> processedCommands) {
    final List<ScriptExecutionBlock> blocks = [];
    List<String>? currentBashCommands;
    List<String>? currentServerBashCommands;

    for (final command in processedCommands) {
      var trimmed = command.trim();
      if (trimmed.startsWith('\$')) {
        trimmed = trimmed.substring(1).trim();
      }
      
      final lowerTrimmed = trimmed.toLowerCase();

      // Nhãn bắt đầu khối Bash Server
      if (lowerTrimmed.startsWith('#bash server')) {
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
      else if (lowerTrimmed.startsWith('#bash')) {
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
      else if (lowerTrimmed.startsWith('#endbash') || 
               lowerTrimmed.startsWith('#end bash') || 
               lowerTrimmed.startsWith('#end') || 
               lowerTrimmed.startsWith('#adb')) {
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
          if (trimmed.isEmpty || (trimmed.startsWith('#') && !lowerTrimmed.startsWith('#bash'))) {
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
