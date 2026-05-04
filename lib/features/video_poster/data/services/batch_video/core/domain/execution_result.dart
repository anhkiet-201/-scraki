/// Represents the outcome of an FFmpeg execution or a rendering task.
class ExecutionResult {
  /// Whether the operation completed successfully.
  final bool success;
  /// List of log messages or error details produced during execution.
  final List<String> logs;
  /// The path to the resulting file, if successful.
  final String? outputPath;

  ExecutionResult({
    required this.success,
    this.logs = const [],
    this.outputPath,
  });

  /// Creates a failed result with a specific error message.
  factory ExecutionResult.failure(String error) {
    return ExecutionResult(success: false, logs: [error]);
  }

  /// Creates a successful result with the path to the generated output.
  factory ExecutionResult.success(String path) {
    return ExecutionResult(success: true, logs: [], outputPath: path);
  }
}
