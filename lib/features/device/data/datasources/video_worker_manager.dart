import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/logger.dart';

import 'dart:math';

/// Tin nhắn gửi tới Worker Isolate
class VideoWorkerCommand {
  final String type; // 'start', 'stop', 'control', 'pause', 'resume'
  final String sessionId;
  final String url;
  final RootIsolateToken? token;
  final List<int>? controlData;

  VideoWorkerCommand({
    required this.type,
    required this.sessionId,
    required this.url,
    this.token,
    this.controlData,
  });
}

/// Tin nhắn Worker Isolate gửi về Main Isolate
class VideoWorkerEvent {
  final String sessionId;
  final String type; // 'error', 'ports_ready', 'resolution_ready'
  final dynamic data;

  VideoWorkerEvent({required this.sessionId, required this.type, this.data});
}

typedef VideoWorkerListener = void Function(VideoWorkerEvent);

@lazySingleton
class VideoWorkerManager {
  // Logic: Use available cores, but cap at 4 (Efficiency usually drops after 4 parallel heavy decoders on typical P-core counts)
  // Ensure at least 2 workers for basic concurrency.
  int get _numWorkers => max(2, min(Platform.numberOfProcessors, 4));
  final List<_WorkerHandle> _workers = [];
  int _nextWorkerIndex = 0;

  final Map<String, VideoWorkerListener> _listeners = {};

  Future<void>? _initFuture;

  Future<void> init() {
    if (_workers.length == _numWorkers) return Future.value();
    _initFuture ??= _initializeWorkers();
    return _initFuture!;
  }

  Future<void> _initializeWorkers() async {
    try {
      logger.i(
        '[VideoWorkerManager] Initializing pool with $_numWorkers workers',
      );
      // Fill until full to handle partial initialization or retries
      while (_workers.length < _numWorkers) {
        final index = _workers.length;
        final handle = await _spawnWorker(index);
        _workers.add(handle);
      }
    } catch (e) {
      _initFuture = null; // Allow retry on failure
      rethrow;
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
      final completer = _pendingSessions['${event.sessionId}_${event.type}'];
      if (completer != null) {
        completer.complete(event.data);
        _pendingSessions.remove('${event.sessionId}_${event.type}');
      }
    } else if (event.type == 'clipboard_update') {
      _handleClipboardUpdate(event.sessionId, event.data as String);
    }
    _listeners[event.sessionId]?.call(event);
  }

  void _handleClipboardUpdate(String sessionId, String text) {
    logger.i(
      '[VideoWorkerManager] Clipboard update from session $sessionId: $text',
    );
    Clipboard.setData(ClipboardData(text: text));
  }

  final Map<String, Completer<dynamic>> _pendingSessions = {};

  Future<dynamic> waitForEvent(String sessionId, String type) {
    final completer = Completer<dynamic>();
    _pendingSessions['${sessionId}_$type'] = completer;
    return completer.future;
  }

  Future<dynamic> startMirroring(
    String sessionId, {
    VideoWorkerListener? listener,
  }) async {
    await init();

    if (listener != null) _listeners[sessionId] = listener;

    final portsFuture = waitForEvent(sessionId, 'ports_ready');

    final worker = _workers[_nextWorkerIndex];
    _nextWorkerIndex = (_nextWorkerIndex + 1) % _numWorkers;

    logger.i(
      '[VideoWorkerManager] Assigning $sessionId to worker (Total sessions: ${_workers.length})',
    );

    worker.sendPort.send(
      VideoWorkerCommand(
        type: 'start',
        sessionId: sessionId,
        url: '', // Not used anymore, worker will bind its own ports
        token: RootIsolateToken.instance,
      ),
    );

    return portsFuture;
  }

  void stopMirroring(String sessionId) {
    _listeners.remove(sessionId);
    for (final worker in _workers) {
      worker.sendPort.send(
        VideoWorkerCommand(
          type: 'stop',
          sessionId: sessionId,
          url: '', // Not needed for stop
        ),
      );
    }
  }

  void sendControl(String sessionId, List<int> data) {
    for (final worker in _workers) {
      worker.sendPort.send(
        VideoWorkerCommand(
          type: 'control',
          sessionId: sessionId,
          url: '',
          controlData: data,
        ),
      );
    }
  }

  void pauseMirroring(String sessionId) {
    for (final worker in _workers) {
      worker.sendPort.send(
        VideoWorkerCommand(type: 'pause', sessionId: sessionId, url: ''),
      );
    }
  }

  void resumeMirroring(String sessionId) {
    for (final worker in _workers) {
      worker.sendPort.send(
        VideoWorkerCommand(type: 'resume', sessionId: sessionId, url: ''),
      );
    }
  }

  void dispose() {
    for (final worker in _workers) {
      worker.isolate.kill();
    }
    _workers.clear();
    _initFuture = null;
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
            message.sessionId,
            message.url,
            eventPort,
          );
          sessions[message.sessionId] = session;
          session.start();
          break;
        case 'stop':
          sessions[message.sessionId]?.stop();
          sessions.remove(message.sessionId);
          break;
        case 'control':
          if (message.controlData != null) {
            sessions[message.sessionId]?.sendControl(message.controlData!);
          }
          break;
        case 'pause':
          sessions[message.sessionId]?.pause();
          break;
        case 'resume':
          sessions[message.sessionId]?.resume();
          break;
      }
    }
  }
}

/// Thực thi xử lý video thô trong Isolate
class _IsolateVideoSession {
  final String sessionId;
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

  _IsolateVideoSession(this.sessionId, this.url, this.eventPort);

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
          sessionId: sessionId,
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
            '[Isolate-Video] Accepted VIDEO socket for $sessionId (Count: $_connectionCount)',
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
            print('[Isolate-Video] VIDEO socket closed for $sessionId');
            _adbSocket = null;
            _adbSubscription?.cancel();
            eventPort?.send(
              VideoWorkerEvent(sessionId: sessionId, type: 'connection_lost'),
            );
          });
        } else if (_controlSocket == null) {
          print(
            '[Isolate-Video] Accepted CONTROL socket for $sessionId (Count: $_connectionCount)',
          );
          _controlSocket = socket;
          _controlSocket!.listen(
            _handleControlData,
            onDone: () {
              print('[Isolate-Video] CONTROL socket closed for $sessionId');
              _controlSocket = null;
              eventPort?.send(
                VideoWorkerEvent(sessionId: sessionId, type: 'connection_lost'),
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

          // Always send config header first to ensure decoder has parameters
          // even if initial buffer was truncated.
          if (_configHeader.isNotEmpty) {
            _playerSocket!.add(_configHeader);
          }

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
        VideoWorkerEvent(
          sessionId: sessionId,
          type: 'error',
          data: e.toString(),
        ),
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
            sessionId: sessionId,
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
        if (_initialBuffer.length > 2000) _initialBuffer.removeAt(0);
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

        print(
          '[Isolate-Video] Received clipboard update from session $sessionId: $text',
        );
        eventPort?.send(
          VideoWorkerEvent(
            sessionId: sessionId,
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
    print('[Isolate-Video] Session $sessionId paused decoding');
  }

  void resume() {
    _isPaused = false;
    print('[Isolate-Video] Session $sessionId resumed decoding');
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
