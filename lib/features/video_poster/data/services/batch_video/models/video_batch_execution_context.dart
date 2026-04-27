import 'dart:io';

/// Class quản lý trạng thái thực thi của một lượt tạo video hàng loạt.
/// Thay thế cho BatchVideoStateMixin để cô lập dữ liệu giữa các lần chạy.
class VideoBatchExecutionContext {
  bool cancelled = false;
  final List<Process> activeProcesses = [];

  void cancel() {
    cancelled = true;
    final processes = List<Process>.from(activeProcesses);
    activeProcesses.clear();
    for (final process in processes) {
      try {
        if (Platform.isWindows) {
          process.kill();
        } else {
          process.kill(ProcessSignal.sigterm);
        }
      } catch (_) {}
    }
  }

  void addProcess(Process process) {
    activeProcesses.add(process);
  }

  void removeProcess(Process process) {
    activeProcesses.remove(process);
  }
}
