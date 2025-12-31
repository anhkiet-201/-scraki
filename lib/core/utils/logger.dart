import 'package:logger/logger.dart';

/// Centralized logger instance for the Scraki project.
///
/// Use [logger.d], [logger.i], [logger.w], [logger.e] for different log levels.
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.dateAndTime,
  ),
);
