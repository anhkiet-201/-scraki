enum LogType {
  command,
  info,
  error,
  output,
}

class LogEntry {
  final DateTime timestamp;
  final String? serial;
  final String? deviceModel;
  final String message;
  final LogType type;
  final int? deviceCount;
  final bool overwriteLast;
  /// ID của process execution sinh ra entry này.
  /// Dùng để scope overwrite chỉ trong phạm vi cùng một lần chạy lệnh.
  /// null cho các log không phải từ process (command header, v.v.).
  final String? executionId;

  LogEntry({
    DateTime? timestamp,
    this.serial,
    this.deviceModel,
    required this.message,
    required this.type,
    this.deviceCount,
    this.overwriteLast = false,
    this.executionId,
  }) : timestamp = timestamp ?? DateTime.now();
  
  String get formattedTime => "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}";
}
