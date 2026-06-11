abstract class ScriptExecutionBlock {}

class SingleCommandBlock extends ScriptExecutionBlock {
  final String command;
  SingleCommandBlock(this.command);
}

class BashScriptBlock extends ScriptExecutionBlock {
  final List<String> commands;
  BashScriptBlock(this.commands);
}

class ScriptExecutionParser {
  /// Phân tích danh sách lệnh thô đã nội suy thành các khối thực thi (Single vs Bash Batch)
  static List<ScriptExecutionBlock> parse(List<String> processedCommands) {
    final List<ScriptExecutionBlock> blocks = [];
    List<String>? currentBashCommands;

    for (final command in processedCommands) {
      var trimmed = command.trim();
      if (trimmed.startsWith('\$')) {
        trimmed = trimmed.substring(1).trim();
      }
      
      // Nhãn bắt đầu khối Bash
      if (trimmed.startsWith('#Bash') || trimmed.startsWith('#bash')) {
        if (currentBashCommands != null) {
          blocks.add(BashScriptBlock(currentBashCommands));
        }
        currentBashCommands = [];
      } 
      // Nhãn kết thúc khối Bash
      else if (trimmed.startsWith('#EndBash') || 
               trimmed.startsWith('#endbash') || 
               trimmed.startsWith('#Adb') || 
               trimmed.startsWith('#adb')) {
        if (currentBashCommands != null) {
          blocks.add(BashScriptBlock(currentBashCommands));
          currentBashCommands = null;
        }
      } 
      // Xử lý các lệnh thông thường
      else {
        if (currentBashCommands != null) {
          currentBashCommands.add(command);
        } else {
          // Bỏ qua dòng trống hoặc dòng comment không phải nhãn
          if (trimmed.isEmpty || (trimmed.startsWith('#') && !trimmed.startsWith('#Bash') && !trimmed.startsWith('#bash'))) {
            continue;
          }
          blocks.add(SingleCommandBlock(command));
        }
      }
    }

    if (currentBashCommands != null) {
      blocks.add(BashScriptBlock(currentBashCommands));
    }

    return blocks;
  }
}
