import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Custom log filter to control output based on environment and level.
class ScrakiLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kDebugMode) {
      return true;
    }
    // In release/profile mode, only log warnings and errors
    return event.level.index >= Level.warning.index;
  }
}

/// Centralized logger instance for the Scraki project.
final logger = Logger(
  filter: ScrakiLogFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.dateAndTime,
  ),
);
