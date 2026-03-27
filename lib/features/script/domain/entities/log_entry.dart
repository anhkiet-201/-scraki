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

  LogEntry({
    DateTime? timestamp,
    this.serial,
    this.deviceModel,
    required this.message,
    required this.type,
    this.deviceCount,
  }) : timestamp = timestamp ?? DateTime.now();
  
  String get formattedTime => "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}";
}
