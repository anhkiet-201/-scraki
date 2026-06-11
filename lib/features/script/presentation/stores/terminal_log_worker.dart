import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:injectable/injectable.dart';
import 'package:scraki/features/script/domain/entities/log_entry.dart';
import 'package:scraki/features/device/domain/services/device_shell.dart';

/// Worker sử dụng Background Isolate để quản lý việc khởi chạy tiến trình Shell (Process.start),
/// lắng nghe luồng log, xử lý gom lô (batching) và phản hồi lại Main Thread.
@lazySingleton
class TerminalLogWorker {
  Isolate? _isolate;
  SendPort? _toIsolatePort;
  final ReceivePort _fromIsolatePort = ReceivePort();

  // Callbacks phản hồi về Main Thread
  void Function(List<LogEntry> globalLogs, Map<String, List<LogEntry>> deviceLogs)? onLogsReceived;
  void Function(String serial, bool isRunning)? onShellStateChanged;

  // Bản đồ lưu các Completer để đợi lệnh chạy xong
  final Map<String, Completer<void>> _pendingCommands = {};

  Future<void> init() async {
    final completer = Completer<void>();
    _isolate = await Isolate.spawn(_isolateEntryPoint, _fromIsolatePort.sendPort);

    _fromIsolatePort.listen((message) {
      if (message is SendPort) {
        _toIsolatePort = message;
        completer.complete();
      } else if (message is Map<String, dynamic>) {
        final type = message['type'] as String;
        if (type == 'logs') {
          final globalRaw = message['global'] as List;
          final deviceRaw = message['device'] as Map;

          final global = globalRaw.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            return LogEntry(
              timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
              serial: map['serial'] as String?,
              deviceModel: map['deviceModel'] as String?,
              message: map['message'] as String,
              type: LogType.values[map['type'] as int],
              deviceCount: map['deviceCount'] as int?,
              overwriteLast: map['overwriteLast'] as bool? ?? false,
              executionId: map['executionId'] as String?,
            );
          }).toList();

          final device = deviceRaw.map((k, v) {
            final list = (v as List).map((e) {
              final map = Map<String, dynamic>.from(e as Map);
              return LogEntry(
                timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
                serial: map['serial'] as String?,
                deviceModel: map['deviceModel'] as String?,
                message: map['message'] as String,
                type: LogType.values[map['type'] as int],
                deviceCount: map['deviceCount'] as int?,
                overwriteLast: map['overwriteLast'] as bool? ?? false,
                executionId: map['executionId'] as String?,
              );
            }).toList();
            return MapEntry(k as String, list);
          });

          onLogsReceived?.call(global, device);
        } else if (type == 'shell_state') {
          final serial = message['serial'] as String;
          final isRunning = message['isRunning'] as bool;
          onShellStateChanged?.call(serial, isRunning);
        } else if (type == 'command_exit') {
          final commandId = message['commandId'] as String;
          final error = message['error'] as String?;
          final completer = _pendingCommands.remove(commandId);
          if (completer != null) {
            if (error != null) {
              completer.completeError(error);
            } else {
              completer.complete();
            }
          }
        }
      }
    });

    return completer.future;
  }

  /// Gửi yêu cầu khởi chạy tiến trình tới Isolate
  Future<void> executeCommand({
    required String commandId,
    required String serial,
    required String executable,
    required List<String> arguments,
    String? modelName,
    String? stdin,
  }) async {
    final completer = Completer<void>();
    _pendingCommands[commandId] = completer;

    _toIsolatePort?.send({
      'type': 'start',
      'commandId': commandId,
      'serial': serial,
      'executable': executable,
      'arguments': arguments,
      'modelName': modelName,
      'stdin': stdin,
    });

    return completer.future;
  }

  /// Gửi yêu cầu dừng một tiến trình cụ thể tới Isolate
  void stopCommand(String serial) {
    _toIsolatePort?.send({
      'type': 'stop',
      'serial': serial,
    });
  }

  /// Gửi yêu cầu dừng tất cả tiến trình tới Isolate
  void stopAll() {
    _toIsolatePort?.send({
      'type': 'stop_all',
    });
  }

  /// Gửi log nghiệp vụ từ Main Thread sang Isolate để gom lô (batch) đồng bộ.
  void addLog({
    required String message,
    required LogType type,
    String? serial,
    String? model,
    int? deviceCount,
  }) {
    _toIsolatePort?.send({
      'type': 'add_log',
      'message': message,
      'serial': serial,
      'model': model,
      'logType': type.index,
      'deviceCount': deviceCount,
    });
  }

  void dispose() {
    stopAll();
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _fromIsolatePort.close();
  }
}

/// Điểm khởi chạy của Background Isolate (được chạy độc lập trên CPU core khác)
void _isolateEntryPoint(SendPort sendPort) {
  final toMainPort = ReceivePort();
  sendPort.send(toMainPort.sendPort);

  // Bản đồ quản lý các tiến trình đang hoạt động
  final activeProcesses = <String, Process>{};

  // Bộ đệm gom lô log (chứa Map để tránh lỗi Serialization của Isolate)
  final List<Map<String, dynamic>> globalLogBuffer = [];
  final Map<String, List<Map<String, dynamic>>> deviceLogBuffer = {};

  Timer? batchTimer;

  void flushLogs() {
    if (globalLogBuffer.isEmpty && deviceLogBuffer.isEmpty) return;

    sendPort.send({
      'type': 'logs',
      'global': List<Map<String, dynamic>>.from(globalLogBuffer),
      'device': Map<String, List<Map<String, dynamic>>>.from(
        deviceLogBuffer.map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v))),
      ),
    });

    globalLogBuffer.clear();
    deviceLogBuffer.clear();
  }

  void addLog(String message, String? serial, String? model, LogType type, int? deviceCount, {bool overwriteLast = false, String? executionId}) {
    final cleanMsg = message.trim();
    if (cleanMsg.isEmpty) return;

    final entryMap = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'serial': serial,
      'deviceModel': model,
      'message': cleanMsg,
      'type': type.index,
      'deviceCount': deviceCount,
      'overwriteLast': overwriteLast,
      'executionId': executionId,
    };

    globalLogBuffer.add(entryMap);
    if (serial != null) {
      (deviceLogBuffer[serial] ??= []).add(entryMap);
    }

    // Cơ chế Batching log sau mỗi 100ms
    batchTimer ??= Timer(const Duration(milliseconds: 100), () {
      batchTimer = null;
      flushLogs();
    });
  }

  toMainPort.listen((message) async {
    if (message is Map<String, dynamic>) {
      final type = message['type'] as String;

      if (type == 'start') {
        final commandId = message['commandId'] as String;
        final serial = message['serial'] as String;
        final executable = message['executable'] as String;
        final arguments = (message['arguments'] as List).cast<String>();
        final stdinPayload = message['stdin'] as String?;
        final modelName = message['modelName'] as String?;

        // Dừng tiến trình cũ nếu đang chạy trên serial này
        if (activeProcesses.containsKey(serial)) {
          activeProcesses[serial]?.kill();
          activeProcesses.remove(serial);
        }

        // Báo trạng thái running về Main
        sendPort.send({
          'type': 'shell_state',
          'serial': serial,
          'isRunning': true,
        });

        try {
          final process = await Process.start(executable, arguments);
          activeProcesses[serial] = process;

          // Dùng Completer để track khi nào stdout/stderr drain xong,
          // tránh deadlock do backpressure khi buffer đầy.
          final stdoutDone = Completer<void>();
          final stderrDone = Completer<void>();

          _handleProcessStream(
            stream: process.stdout.transform(utf8.decoder),
            serial: serial,
            modelName: modelName,
            type: LogType.output,
            onLog: addLog,
            onDone: stdoutDone.complete,
            executionId: commandId,
          );

          _handleProcessStream(
            stream: process.stderr.transform(utf8.decoder),
            serial: serial,
            modelName: modelName,
            type: LogType.error,
            onLog: addLog,
            onDone: stderrDone.complete,
            executionId: commandId,
          );

          if (stdinPayload != null) {
            process.stdin.write(stdinPayload);
            await process.stdin.flush();
            await process.stdin.close();
          }

          // Chờ đồng thời process exit + drain cả hai stream để tránh deadlock.
          final results = await Future.wait<dynamic>([
            process.exitCode,
            stdoutDone.future,
            stderrDone.future,
          ]);
          final int exitCode = results[0] as int;

          activeProcesses.remove(serial);

          final state = ShellState.fromCode(exitCode);
          final String logs = 'Process exited with code: $exitCode - ${state.message}';
          addLog(logs, serial, modelName, exitCode == 0 ? LogType.info : LogType.error, null);

          // Flush toàn bộ log buffer TRƯỚC khi gửi command_exit để đảm bảo
          // thứ tự log đúng: output của lệnh này phải đến main trước khi
          // lệnh tiếp theo bắt đầu.
          batchTimer?.cancel();
          batchTimer = null;
          flushLogs();

          sendPort.send({
            'type': 'shell_state',
            'serial': serial,
            'isRunning': false,
          });

          sendPort.send({
            'type': 'command_exit',
            'commandId': commandId,
            if (exitCode != 0) 'error': logs,
          });
        } catch (e) {
          activeProcesses.remove(serial);

          batchTimer?.cancel();
          batchTimer = null;
          flushLogs();

          sendPort.send({
            'type': 'shell_state',
            'serial': serial,
            'isRunning': false,
          });

          sendPort.send({
            'type': 'command_exit',
            'commandId': commandId,
            'error': e.toString(),
          });
        }
      } else if (type == 'add_log') {
        final messageText = message['message'] as String;
        final serial = message['serial'] as String?;
        final model = message['model'] as String?;
        final logTypeIndex = message['logType'] as int;
        final deviceCount = message['deviceCount'] as int?;
        addLog(
          messageText,
          serial,
          model,
          LogType.values[logTypeIndex],
          deviceCount,
        );
      } else if (type == 'stop') {
        final serial = message['serial'] as String;
        if (activeProcesses.containsKey(serial)) {
          activeProcesses[serial]?.kill();
          activeProcesses.remove(serial);
        }
      } else if (type == 'stop_all') {
        for (final p in activeProcesses.values) {
          p.kill();
        }
        activeProcesses.clear();
      }
    }
  });
}

void _handleProcessStream({
  required Stream<String> stream,
  required String serial,
  required String? modelName,
  required LogType type,
  required void Function(String message, String? serial, String? model, LogType type, int? deviceCount, {bool overwriteLast, String? executionId}) onLog,
  void Function()? onDone,
  String? executionId,
}) {
  String buffer = '';
  bool overwrite = false;
  stream.listen((chunk) {
    buffer += chunk;
    while (true) {
      int pos = -1;
      for (int i = 0; i < buffer.length; i++) {
        if (buffer[i] == '\n' || buffer[i] == '\r') {
          pos = i;
          break;
        }
      }
      if (pos == -1) break;

      if (buffer[pos] == '\r' && pos == buffer.length - 1) {
        break;
      }

      final char = buffer[pos];
      final line = buffer.substring(0, pos);
      
      int skip = 1;
      if (char == '\r' && pos + 1 < buffer.length && buffer[pos + 1] == '\n') {
        skip = 2;
      }
      
      buffer = buffer.substring(pos + skip);
      overwrite = (char == '\r' && skip == 1);
      onLog(line, serial, modelName, type, null, overwriteLast: overwrite, executionId: executionId);
    }
  }, onDone: () {
    if (buffer.isNotEmpty) {
      if (buffer.endsWith('\r')) {
        final cleanBuffer = buffer.substring(0, buffer.length - 1);
        onLog(cleanBuffer, serial, modelName, type, null, overwriteLast: overwrite, executionId: executionId);
      } else {
        onLog(buffer, serial, modelName, type, null, overwriteLast: overwrite, executionId: executionId);
      }
    }
    overwrite = false;
    onDone?.call();
  });
}
