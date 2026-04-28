class ExecutionResult {
  final bool success;
  final List<String> logs;
  final String? outputPath;

  ExecutionResult({
    required this.success,
    required this.logs,
    this.outputPath,
  });

  factory ExecutionResult.failure(String error) {
    return ExecutionResult(success: false, logs: [error]);
  }

  factory ExecutionResult.success(String path) {
    return ExecutionResult(success: true, logs: [], outputPath: path);
  }
}
