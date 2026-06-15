import 'package:injectable/injectable.dart';
import 'package:scraki/features/script/domain/entities/log_entry.dart';

/// Helper class chịu trách nhiệm định dạng và xử lý logs (như gom lô, ghi đè dòng log với \r).
/// Không quản lý state Mobx hay Process Isolate.
@lazySingleton
class TerminalLogWorker {
  /// Định dạng log nghiệp vụ thô thành LogEntry
  LogEntry parseSingleLog({
    required String message,
    required LogType type,
    String? serial,
    String? model,
    int? deviceCount,
  }) {
    return LogEntry(
      timestamp: DateTime.now(),
      message: message,
      type: type,
      serial: serial,
      deviceModel: model,
      deviceCount: deviceCount,
    );
  }

  /// Xử lý một lô raw global logs thô và tìm kiếm xem có dòng nào cần ghi đè hay không.
  /// Gọi callback để Store cập nhật trực tiếp vào list observable.
  void processGlobalLogs({
    required List<dynamic> globalRaw,
    required List<LogEntry> currentGlobalLogs,
    required void Function(LogEntry entry, int? indexToReplace) onLogProcessed,
  }) {
    final tempLogs = List<LogEntry>.from(currentGlobalLogs);

    for (final raw in globalRaw) {
      final map = Map<String, dynamic>.from(raw as Map);
      final entry = LogEntry(
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        serial: map['serial'] as String?,
        deviceModel: map['deviceModel'] as String?,
        message: map['message'] as String,
        type: LogType.values[map['type'] as int],
        deviceCount: map['deviceCount'] as int?,
        overwriteLast: map['overwriteLast'] as bool? ?? false,
        executionId: map['executionId'] as String?,
      );

      final index = tempLogs.lastIndexWhere((e) {
        if (e.type != LogType.output && e.type != LogType.error) return false;
        if (entry.executionId != null) return e.executionId == entry.executionId;
        return e.serial == entry.serial;
      });

      if (index != -1 && tempLogs[index].overwriteLast) {
        tempLogs[index] = entry;
        onLogProcessed(entry, index);
      } else {
        tempLogs.add(entry);
        onLogProcessed(entry, null);
      }
    }
  }

  /// Xử lý một lô raw device logs thô và tìm kiếm xem có dòng nào cần ghi đè hay không.
  /// Gọi callback để Store cập nhật trực tiếp vào list observable của từng thiết bị.
  void processDeviceLogs({
    required Map<dynamic, dynamic> deviceRaw,
    required Map<String, List<LogEntry>> currentDeviceLogs,
    required void Function(String serial, LogEntry entry, int? indexToReplace) onLogProcessed,
  }) {
    final tempDeviceLogs = <String, List<LogEntry>>{};
    currentDeviceLogs.forEach((k, v) {
      tempDeviceLogs[k] = List<LogEntry>.from(v);
    });

    deviceRaw.forEach((k, v) {
      final serial = k as String;
      final listRaw = v as List;
      final currentList = tempDeviceLogs[serial] ??= [];

      for (final raw in listRaw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final entry = LogEntry(
          timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
          serial: map['serial'] as String?,
          deviceModel: map['deviceModel'] as String?,
          message: map['message'] as String,
          type: LogType.values[map['type'] as int],
          deviceCount: map['deviceCount'] as int?,
          overwriteLast: map['overwriteLast'] as bool? ?? false,
          executionId: map['executionId'] as String?,
        );

        final index = currentList.lastIndexWhere((e) {
          if (e.type != LogType.output && e.type != LogType.error) return false;
          if (entry.executionId != null) return e.executionId == entry.executionId;
          return e.serial == entry.serial;
        });

        if (index != -1 && currentList[index].overwriteLast) {
          currentList[index] = entry;
          onLogProcessed(serial, entry, index);
        } else {
          currentList.add(entry);
          onLogProcessed(serial, entry, null);
        }
      }
    });
  }
}
