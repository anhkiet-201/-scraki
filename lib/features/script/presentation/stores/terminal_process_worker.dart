import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:injectable/injectable.dart';
import 'package:scraki/features/script/domain/entities/log_entry.dart';
import 'package:scraki/features/device/domain/services/device_shell.dart';

/// Worker sử dụng Background Isolate để quản lý việc khởi chạy tiến trình Shell (Process.start)
/// và gửi thông tin raw logs, shell states, command exit về Main Thread.
@lazySingleton
class TerminalProcessWorker {
  Isolate? _isolate;
  SendPort? _toIsolatePort;
  final ReceivePort _fromIsolatePort = ReceivePort();

  // Callbacks phản hồi về Main Thread
  void Function(List<dynamic> globalRaw, Map<dynamic, dynamic> deviceRaw)?
  onRawLogsReceived;
  void Function(String serial, bool isRunning)? onShellStateChanged;

  // Bản đồ lưu các Completer để đợi lệnh chạy xong
  final Map<String, Completer<int>> _pendingCommands = {};

  Future<void> init() async {
    final completer = Completer<void>();
    _isolate = await Isolate.spawn(
      _processIsolateEntryPoint,
      _fromIsolatePort.sendPort,
    );

    _fromIsolatePort.listen((message) {
      if (message is SendPort) {
        _toIsolatePort = message;
        completer.complete();
      } else if (message is Map<String, dynamic>) {
        final type = message['type'] as String;
        if (type == 'logs') {
          final globalRaw = message['global'] as List;
          final deviceRaw = message['device'] as Map;
          onRawLogsReceived?.call(globalRaw, deviceRaw);
        } else if (type == 'shell_state') {
          final serial = message['serial'] as String;
          final isRunning = message['isRunning'] as bool;
          onShellStateChanged?.call(serial, isRunning);
        } else if (type == 'command_exit') {
          final commandId = message['commandId'] as String;
          final exitCode = message['exitCode'] as int? ?? 0;
          final completer = _pendingCommands.remove(commandId);
          if (completer != null) {
            completer.complete(exitCode);
          }
        }
      }
    });

    return completer.future;
  }

  /// Gửi yêu cầu khởi chạy tiến trình tới Isolate.
  /// [serial] dùng để báo cáo trạng thái và log về Main Thread.
  /// [processKey] (tuỳ chọn) dùng để quản lý tiến trình trong activeProcesses.
  /// Nếu không truyền [processKey], mặc định sử dụng [serial].
  /// Dùng [processKey] khác [serial] khi muốn tiến trình server chạy độc lập
  /// với tiến trình ADB của cùng thiết bị (ví dụ: processKey = '__server__$serial').
  Future<int> executeCommand({
    required String commandId,
    required String serial,
    required String executable,
    required List<String> arguments,
    String? modelName,
    String? stdin,
    String? processKey,
  }) async {
    final completer = Completer<int>();
    _pendingCommands[commandId] = completer;

    _toIsolatePort?.send({
      'type': 'start',
      'commandId': commandId,
      'serial': serial,
      'processKey': processKey ?? serial,
      'executable': executable,
      'arguments': arguments,
      'modelName': modelName,
      'stdin': stdin,
    });

    return completer.future;
  }

  /// Gửi yêu cầu dừng một tiến trình cụ thể tới Isolate
  void stopCommand(String serial) {
    _toIsolatePort?.send({'type': 'stop', 'serial': serial});
  }

  /// Gửi yêu cầu dừng tất cả tiến trình tới Isolate
  void stopAll() {
    _toIsolatePort?.send({'type': 'stop_all'});
  }

  void dispose() {
    stopAll();
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _fromIsolatePort.close();
  }
}

/// Điểm khởi chạy của Background Isolate (được chạy độc lập trên CPU core khác)
void _processIsolateEntryPoint(SendPort sendPort) {
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
        deviceLogBuffer.map(
          (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)),
        ),
      ),
    });

    globalLogBuffer.clear();
    deviceLogBuffer.clear();
  }

  void addLog(
    String message,
    String? serial,
    String? model,
    LogType type,
    int? deviceCount, {
    bool overwriteLast = false,
    String? executionId,
  }) {
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
        // processKey: khóa trong activeProcesses. Có thể khác serial khi tiến trình
        // server bash chạy độc lập với tiến trình ADB của cùng thiết bị.
        final processKey = message['processKey'] as String? ?? serial;
        final executable = message['executable'] as String;
        final arguments = (message['arguments'] as List).cast<String>();
        final stdinPayload = message['stdin'] as String?;
        final modelName = message['modelName'] as String?;

        // Dừng tiến trình cũ nếu đang chạy với cùng processKey
        if (activeProcesses.containsKey(processKey)) {
          final p = activeProcesses[processKey];
          if (p != null) _killProcess(p);
          activeProcesses.remove(processKey);
        }

        // Báo trạng thái running về Main
        sendPort.send({
          'type': 'shell_state',
          'serial': serial,
          'isRunning': true,
        });

        try {
          final process = await Process.start(executable, arguments);
          activeProcesses[processKey] = process;

          // Dùng Completer để track khi nào stdout/stderr drain xong,
          // tránh deadlock do backpressure khi buffer đầy.
          final stdoutDone = Completer<void>();
          final stderrDone = Completer<void>();

          _handleProcessStream(
            stream: process.stdout.transform(
              const Utf8Decoder(allowMalformed: true),
            ),
            serial: serial,
            modelName: modelName,
            type: LogType.output,
            onLog: addLog,
            onDone: stdoutDone.complete,
            executionId: commandId,
          );

          _handleProcessStream(
            stream: process.stderr.transform(
              const Utf8Decoder(allowMalformed: true),
            ),
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
          }
          await process.stdin.close();

          // Chờ đồng thời process exit + drain cả hai stream để tránh deadlock.
          final results = await Future.wait<dynamic>([
            process.exitCode,
            stdoutDone.future,
            stderrDone.future,
          ]);
          final int exitCode = results[0] as int;
          activeProcesses.remove(processKey);

          final state = ShellState.fromCode(exitCode);
          final String logs =
              'Process exited with code: $exitCode - ${state.message}';
          addLog(
            logs,
            serial,
            modelName,
            exitCode == 0 ? LogType.info : LogType.error,
            null,
          );

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
            'exitCode': exitCode,
            if (exitCode != 0 && exitCode != 99) 'error': logs,
          });
        } catch (e) {
          activeProcesses.remove(processKey);

          final errorMsg =
              'Lỗi hệ thống khi khởi chạy tiến trình: ${e.toString()}';
          addLog(errorMsg, serial, modelName, LogType.error, null);

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
            'exitCode': -1,
          });
        }
      } else if (type == 'stop') {
        final serial = message['serial'] as String;
        // Dừng cả tiến trình ADB và tiến trình server bash của thiết bị
        for (final key in [serial, '__server__$serial']) {
          if (activeProcesses.containsKey(key)) {
            final p = activeProcesses[key];
            if (p != null) _killProcess(p);
            activeProcesses.remove(key);
          }
        }
      } else if (type == 'stop_all') {
        for (final p in activeProcesses.values) {
          _killProcess(p);
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
  required void Function(
    String message,
    String? serial,
    String? model,
    LogType type,
    int? deviceCount, {
    bool overwriteLast,
    String? executionId,
  })
  onLog,
  void Function()? onDone,
  String? executionId,
}) {
  String buffer = '';
  stream.listen(
    (chunk) {
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
        if (char == '\r' &&
            pos + 1 < buffer.length &&
            buffer[pos + 1] == '\n') {
          skip = 2;
        }

        buffer = buffer.substring(pos + skip);
        final lineOverwrite = (char == '\r' && skip == 1);
        onLog(
          line,
          serial,
          modelName,
          type,
          null,
          overwriteLast: lineOverwrite,
          executionId: executionId,
        );
      }
    },
    onDone: () {
      if (buffer.isNotEmpty) {
        if (buffer.endsWith('\r')) {
          final cleanBuffer = buffer.substring(0, buffer.length - 1);
          onLog(
            cleanBuffer,
            serial,
            modelName,
            type,
            null,
            overwriteLast: true,
            executionId: executionId,
          );
        } else {
          onLog(
            buffer,
            serial,
            modelName,
            type,
            null,
            overwriteLast: false,
            executionId: executionId,
          );
        }
      }
      onDone?.call();
    },
  );
}

void _killProcess(Process process) {
  if (Platform.isWindows) {
    Process.run('taskkill', ['/F', '/T', '/PID', '${process.pid}']);
  } else {
    process.kill();
  }
}
