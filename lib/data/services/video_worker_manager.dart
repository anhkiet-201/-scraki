import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../../../core/utils/logger.dart';

/// Tin nhắn gửi tới Worker Isolate
class VideoWorkerCommand {
  final String type; // 'start', 'stop', 'control', 'pause', 'resume'
  final String serial;
  final String url;
  final RootIsolateToken? token;
  final List<int>? controlData;

  VideoWorkerCommand({
    required this.type,
    required this.serial,
    required this.url,
    this.token,
    this.controlData,
  });
}

/// Tin nhắn Worker Isolate gửi về Main Isolate
class VideoWorkerEvent {
  final String serial;
  final String type; // 'error', 'ports_ready', 'resolution_ready'
  final dynamic data;

  VideoWorkerEvent({required this.serial, required this.type, this.data});
}

typedef VideoWorkerListener = void Function(VideoWorkerEvent);

@lazySingleton
class VideoWorkerManager {
  static const int _numWorkers = 4; // Số lượng Isolate trong pool
  final List<_WorkerHandle> _workers = [];
  int _nextWorkerIndex = 0;

  final Map<String, VideoWorkerListener> _listeners = {};

  Future<void> init() async {
    if (_workers.isNotEmpty) return;

    logger.i(
      '[VideoWorkerManager] Initializing pool with $_numWorkers workers',
    );
    for (int i = 0; i < _numWorkers; i++) {
      final handle = await _spawnWorker(i);
      _workers.add(handle);
    }
  }

  Future<_WorkerHandle> _spawnWorker(int id) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _workerEntryPoint,
      receivePort.sendPort,
      debugName: 'VideoWorker_$id',
    );

    final sendPort = await receivePort.first as SendPort;

    // Lắng nghe sự kiện từ Isolate
    final eventPort = ReceivePort();
    sendPort.send(eventPort.sendPort);

    eventPort.listen((message) {
      if (message is VideoWorkerEvent) {
        _handleWorkerEvent(message);
      }
    });

    return _WorkerHandle(isolate, sendPort);
  }

  void _handleWorkerEvent(VideoWorkerEvent event) {
    if (event.type == 'ports_ready' || event.type == 'resolution_ready') {
      final completer = _pendingSessions['${event.serial}_${event.type}'];
      if (completer != null) {
        completer.complete(event.data);
        _pendingSessions.remove('${event.serial}_${event.type}');
      }
    } else if (event.type == 'clipboard_update') {
      _handleClipboardUpdate(event.serial, event.data as String);
    }
    _listeners[event.serial]?.call(event);
  }

  void _handleClipboardUpdate(String serial, String text) {
    logger.i(
      '[VideoWorkerManager] Clipboard update from device $serial: $text',
    );
    Clipboard.setData(ClipboardData(text: text));
  }

  final Map<String, Completer<dynamic>> _pendingSessions = {};

  Future<dynamic> waitForEvent(String serial, String type) {
    final completer = Completer<dynamic>();
    _pendingSessions['${serial}_$type'] = completer;
    return completer.future;
  }

  Future<dynamic> startMirroring(
    String serial, {
    VideoWorkerListener? listener,
  }) async {
    await init();

    if (listener != null) _listeners[serial] = listener;

    final portsFuture = waitForEvent(serial, 'ports_ready');

    final worker = _workers[_nextWorkerIndex];
    _nextWorkerIndex = (_nextWorkerIndex + 1) % _numWorkers;

    logger.i(
      '[VideoWorkerManager] Assigning $serial to worker (Total sessions: ${_workers.length})',
    );

    worker.sendPort.send(
      VideoWorkerCommand(
        type: 'start',
        serial: serial,
        url: '', // Not used anymore, worker will bind its own ports
        token: RootIsolateToken.instance,
      ),
    );

    return portsFuture;
  }

  void stopMirroring(String serial) {
    for (final worker in _workers) {
      worker.sendPort.send(
        VideoWorkerCommand(
          type: 'stop',
          serial: serial,
          url: '', // Not needed for stop
        ),
      );
    }
  }

  void sendControl(String serial, List<int> data) {
    for (final worker in _workers) {
      worker.sendPort.send(
        VideoWorkerCommand(
          type: 'control',
          serial: serial,
          url: '',
          controlData: data,
        ),
      );
    }
  }

  void pauseMirroring(String serial) {
    for (final worker in _workers) {
      worker.sendPort.send(
        VideoWorkerCommand(type: 'pause', serial: serial, url: ''),
      );
    }
  }

  void resumeMirroring(String serial) {
    for (final worker in _workers) {
      worker.sendPort.send(
        VideoWorkerCommand(type: 'resume', serial: serial, url: ''),
      );
    }
  }

  void dispose() {
    for (final worker in _workers) {
      worker.isolate.kill();
    }
    _workers.clear();
  }
}

class _WorkerHandle {
  final Isolate isolate;
  final SendPort sendPort;

  _WorkerHandle(this.isolate, this.sendPort);
}

/// Điểm khởi đầu của Worker Isolate
void _workerEntryPoint(SendPort managerPort) async {
  final commandPort = ReceivePort();
  managerPort.send(commandPort.sendPort);

  SendPort? eventPort;
  final sessions = <String, _IsolateVideoSession>{};

  await for (final message in commandPort) {
    if (message is SendPort) {
      eventPort = message;
      continue;
    }

    if (message is VideoWorkerCommand) {
      switch (message.type) {
        case 'start':
          if (message.token != null) {
            BackgroundIsolateBinaryMessenger.ensureInitialized(message.token!);
          }
          final session = _IsolateVideoSession(
            message.serial,
            message.url,
            eventPort,
          );
          sessions[message.serial] = session;
          session.start();
          break;
        case 'stop':
          sessions[message.serial]?.stop();
          sessions.remove(message.serial);
          break;
        case 'control':
          if (message.controlData != null) {
            sessions[message.serial]?.sendControl(message.controlData!);
          }
          break;
        case 'pause':
          sessions[message.serial]?.pause();
          break;
        case 'resume':
          sessions[message.serial]?.resume();
          break;
      }
    }
  }
}

/// Thực thi xử lý video thô trong Isolate
class _IsolateVideoSession {
  final String serial;
  final String url;
  final SendPort? eventPort;

  ServerSocket? _adbServerSocket;
  ServerSocket? _proxyServerSocket;
  Socket? _adbSocket;
  Socket? _controlSocket;
  Socket? _playerSocket;
  StreamSubscription<List<int>>? _adbSubscription;
  int _connectionCount = 0;

  // Buffer và parsing
  final List<int> _configHeader = [];
  bool _isFirstFrameReceived = false;
  final List<int> _parseBuffer = [];
  bool _headerParsed = false;
  bool _isPaused = false;

  // Stream buffering for first connect
  final List<List<int>> _initialBuffer = [];
  bool _anyPlayerConnected = false;

  _IsolateVideoSession(this.serial, this.url, this.eventPort);

  Future<void> start() async {
    try {
      // 1. Tạo Server Socket cho ADB (nhận data từ phone)
      _adbServerSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      final adbPort = _adbServerSocket!.port;

      // 2. Tạo Server Socket cho Native Decoder (Proxy)
      _proxyServerSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      final proxyPort = _proxyServerSocket!.port;

      // Báo cáo port về Main Isolate
      eventPort?.send(
        VideoWorkerEvent(
          serial: serial,
          type: 'ports_ready',
          data: {'adbPort': adbPort, 'proxyPort': proxyPort},
        ),
      );

      // Lắng nghe kết nối từ ADB
      _adbServerSocket!.listen((socket) {
        _connectionCount++;
        socket.setOption(SocketOption.tcpNoDelay, true);

        // scrcpy connects Video first, then Control.
        // If it retries, it closes existing and connects again.
        if (_adbSocket == null) {
          print(
            '[Isolate-Video] Accepted VIDEO socket (Count: $_connectionCount)',
          );

          // RESET state for new connection (e.g. scrcpy retry)
          _headerParsed = false;
          _isFirstFrameReceived = false;
          _parseBuffer.clear();
          _configHeader.clear();
          _initialBuffer.clear();
          _adbSubscription?.cancel();

          _adbSocket = socket;
          _adbSubscription = _adbSocket!.listen(_handleAdbData);

          _adbSocket!.done.then((_) {
            print('[Isolate-Video] VIDEO socket closed');
            _adbSocket = null;
            _adbSubscription?.cancel();
            eventPort?.send(
              VideoWorkerEvent(serial: serial, type: 'connection_lost'),
            );
          });
        } else if (_controlSocket == null) {
          print(
            '[Isolate-Video] Accepted CONTROL socket (Count: $_connectionCount)',
          );
          _controlSocket = socket;
          _controlSocket!.listen(
            _handleControlData,
            onDone: () {
              print('[Isolate-Video] CONTROL socket closed');
              _controlSocket = null;
              eventPort?.send(
                VideoWorkerEvent(serial: serial, type: 'connection_lost'),
              );
            },
          );
        }
      });

      // Lắng nghe kết nối từ Player (Native)
      _proxyServerSocket!.listen((socket) {
        _playerSocket = socket;
        _playerSocket!.setOption(SocketOption.tcpNoDelay, true);

        final isFirst = !_anyPlayerConnected;
        _anyPlayerConnected = true;

        if (isFirst) {
          print(
            '[Isolate-Video] Player connected. Dumping initial buffer: ${_initialBuffer.length} chunks',
          );
          for (final chunk in _initialBuffer) {
            _playerSocket!.add(chunk);
          }
          _initialBuffer.clear();
        } else {
          print('[Isolate-Video] Late player connected. Sending Meta only.');
          if (_configHeader.isNotEmpty) {
            _playerSocket!.add(_configHeader);
          }
        }
      });
    } catch (e) {
      eventPort?.send(
        VideoWorkerEvent(serial: serial, type: 'error', data: e.toString()),
      );
    }
  }

  void _handleAdbData(List<int> data) {
    if (!_headerParsed) {
      _parseBuffer.addAll(data);
      if (_parseBuffer.length >= 76) {
        // ScrcpyProtocolParser.headerSize = 76
        _headerParsed = true;

        final headerData = Uint8List.fromList(_parseBuffer.sublist(0, 76));
        final view = ByteData.sublistView(headerData, 64, 76);
        final width = view.getUint32(4);
        final height = view.getUint32(8);

        // Báo cáo Resolution về Main Isolate
        eventPort?.send(
          VideoWorkerEvent(
            serial: serial,
            type: 'resolution_ready',
            data: {'width': width, 'height': height},
          ),
        );

        final remaining = _parseBuffer.sublist(76);
        _parseBuffer.clear();
        if (remaining.isNotEmpty) _processVideoData(remaining);
      }
      return;
    }

    _processVideoData(data);
  }

  void _processVideoData(List<int> data) {
    // Collect config headers (SPS/PPS) if not already done
    if (!_isFirstFrameReceived) {
      _parseBuffer.addAll(data);
      _extractConfigHeaders();
    }

    if (!_anyPlayerConnected || _isPaused) {
      // Still buffering key info but not forwarding to player when paused
      if (!_anyPlayerConnected) {
        _initialBuffer.add(data);
        if (_initialBuffer.length > 500) _initialBuffer.removeAt(0);
      }
      return;
    }

    // Forward to current player
    try {
      _playerSocket?.add(data);
    } catch (_) {
      _anyPlayerConnected = false;
      _playerSocket = null;
    }
  }

  void _extractConfigHeaders() {
    while (_parseBuffer.length >= 12) {
      final headerData = Uint8List.fromList(_parseBuffer.sublist(0, 12));
      final view = ByteData.sublistView(headerData);
      final pts = view.getInt64(0, Endian.big);
      final size = view.getUint32(8, Endian.big);

      // Scrcpy uses 1 << 63 as a flag for metadata packets (CONFIG)
      // Any negative PTS (except maybe specifically documented ones) is treated as meta.
      if (pts < 0) {
        final totalSize = 12 + size;
        if (_parseBuffer.length >= totalSize) {
          final configPacket = _parseBuffer.sublist(0, totalSize);
          _configHeader.addAll(configPacket);
          _parseBuffer.removeRange(0, totalSize);

          // Meta captured, if player is already here, we must forward it
          _playerSocket?.add(configPacket);

          print(
            '[Isolate-Video] Captured Meta Packet: $size bytes (Total Meta: ${_configHeader.length} bytes)',
          );
        } else {
          break;
        }
      } else {
        _isFirstFrameReceived = true;
        print('[Isolate-Video] First data frame reached. PTS: $pts');
        break;
      }
    }
  }

  void sendControl(List<int> data) {
    try {
      _controlSocket?.add(data);
    } catch (_) {}
  }

  final List<int> _controlBuffer = [];

  void _handleControlData(List<int> data) {
    _controlBuffer.addAll(data);

    // Scrcpy Control Message from Device to Client
    // Type 0: Clipboard (Device set its clipboard)
    while (_controlBuffer.isNotEmpty) {
      final type = _controlBuffer[0];
      if (type == 0) {
        // [1 byte Type][4 bytes length][N bytes Text]
        if (_controlBuffer.length < 5) break;

        final view = ByteData.sublistView(Uint8List.fromList(_controlBuffer));
        final length = view.getUint32(1, Endian.big);

        if (_controlBuffer.length < 5 + length) break;

        final textBytes = _controlBuffer.sublist(5, 5 + length);
        final text = utf8.decode(textBytes, allowMalformed: true);

        print('[Isolate-Video] Received clipboard update from device: $text');
        eventPort?.send(
          VideoWorkerEvent(
            serial: serial,
            type: 'clipboard_update',
            data: text,
          ),
        );

        _controlBuffer.removeRange(0, 5 + length);
      } else {
        // Unknown or unhandled message type, skip 1 byte
        _controlBuffer.removeAt(0);
      }
    }
  }

  void pause() {
    _isPaused = true;
    print('[Isolate-Video] Session $serial paused decoding');
  }

  void resume() {
    _isPaused = false;
    print('[Isolate-Video] Session $serial resumed decoding');
    // Ensure meta is sent on resume just in case
    if (_configHeader.isNotEmpty && _playerSocket != null) {
      _playerSocket!.add(_configHeader);
    }
  }

  void stop() {
    _adbSubscription?.cancel();
    _adbSocket?.destroy();
    _controlSocket?.destroy();
    _playerSocket?.destroy();
    _adbServerSocket?.close();
    _proxyServerSocket?.close();
  }
}
