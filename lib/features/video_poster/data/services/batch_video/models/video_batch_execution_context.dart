import 'dart:io';

/// Manages the execution state of a batch video rendering task.
/// 
/// This context tracks active FFmpeg processes and provides a centralized 
/// mechanism to cancel all running operations safely across different platforms.
class VideoBatchExecutionContext {
  /// Whether the task has been requested to cancel.
  bool cancelled = false;
  
  /// List of currently running FFmpeg processes.
  final List<Process> activeProcesses = [];

  /// Cancels all active processes and marks the context as cancelled.
  /// 
  /// Uses SIGTERM on Unix-like systems and standard kill on Windows to 
  /// ensure processes are terminated.
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

  /// Adds a process to the tracking list.
  void addProcess(Process process) {
    activeProcesses.add(process);
  }

  /// Removes a process from the tracking list, typically called when a process exits.
  void removeProcess(Process process) {
    activeProcesses.remove(process);
  }
}
