import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scraki/features/script/domain/entities/log_entry.dart';

Color getDeviceColor(String? serial) {
  if (serial == null) return Colors.grey;
  final int hash = serial.hashCode;
  final List<Color> colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
  ];
  return colors[hash.abs() % colors.length];
}

class LogLineItem extends StatelessWidget {
  final LogEntry log;
  final LogEntry? prevLog;

  const LogLineItem({
    super.key,
    required this.log,
    this.prevLog,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _buildLogLine(theme, log, prevLog);
  }

  Widget _buildLable(LogEntry log) {
    final deviceColor = getDeviceColor(log.serial);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        '[${log.serial ?? "SYS"}] ${log.deviceModel ?? "System"}',
        style: GoogleFonts.firaCode(
          color: deviceColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildLogLine(ThemeData theme, LogEntry log, [LogEntry? prevLog]) {
    switch (log.type) {
      case LogType.command:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    r'$ ',
                    style: GoogleFonts.firaCode(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      log.message,
                      style: GoogleFonts.firaCode(
                        color: const Color(0xFF1E293B), // Slate 800
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (log.deviceCount != null && log.deviceCount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.deviceCount == 1
                            ? '[${log.serial}] ${log.deviceModel ?? "Device"}'
                            : '${log.deviceCount} DEVICCES',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    log.formattedTime,
                    style: GoogleFonts.firaCode(
                      color: const Color(0xFF94A3B8), // Slate 400
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case LogType.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLable(log),
            Text(
              log.message,
              style: GoogleFonts.firaCode(
                color: Colors.red.shade700,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        );
      case LogType.info:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLable(log),
            Text(
              '// ${log.message}',
              style: GoogleFonts.firaCode(
                color: const Color(0xFF94A3B8), // Slate 400
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      case LogType.output:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLable(log),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                log.message,
                style: GoogleFonts.firaCode(
                  fontSize: 12,
                  height: 1.6,
                  color: const Color(0xFF334155), // Slate 700
                ),
              ),
            ),
          ],
        );
    }
  }
}
