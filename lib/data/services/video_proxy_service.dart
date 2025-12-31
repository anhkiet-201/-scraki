import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import '../../core/utils/logger.dart';

/// Represents a single video proxy session for a device.
///
/// This class handles the logic of receiving encoded video data from scrcpy
/// and serving it over a local TCP socket for the native decoder.
class VideoProxySession {
  final Stream<List<int>> scrcpyStream;
  ServerSocket? serverSocket;
  StreamSubscription<List<int>>? _streamSubscription;
  Socket? _playerSocket;
  bool _isPlayerConnected = false;

  // Buffer to hold configuration packets (SPS/PPS) permanently
  final List<int> _configHeader = [];
  bool _isFirstFrameReceived = false;
  final List<int> _parseBuffer = [];

  VideoProxySession(this.scrcpyStream);

  Future<int> start() async {
    // 1. Start listening to Scrcpy stream immediately
    _streamSubscription = scrcpyStream.listen(
      (data) {
        _processData(data);
      },
      onDone: () {
        logger.i('[VideoProxySession] Scrcpy stream done');
        stop();
      },
      onError: (Object e) {
        logger.e('[VideoProxySession] Scrcpy stream error', error: e);
        stop();
      },
    );

    // 2. Start TCP Server for Native Decoder
    serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    final port = serverSocket!.port;
    logger.i('[VideoProxySession] Listening on port $port');

    serverSocket!.listen((socket) {
      logger.i('[VideoProxySession] Player connected to port $port');

      _playerSocket?.destroy();
      _playerSocket = socket;
      _playerSocket!.setOption(SocketOption.tcpNoDelay, true);
      _isPlayerConnected = true;

      // 3. IMMEDIATELY send cached configuration headers to the new player
      if (_configHeader.isNotEmpty) {
        logger.i(
          '[VideoProxySession] Replaying cached config headers (${_configHeader.length} bytes) to new player',
        );
        _playerSocket!.add(_configHeader);
      }

      _playerSocket!.done.then((_) {
        // Only mark disconnected if this is still the active socket
        if (_playerSocket == socket) {
          logger.i('[VideoProxySession] Player disconnected');
          _isPlayerConnected = false;
          _playerSocket = null;
        }
      });
    });

    return port;
  }

  void _processData(List<int> data) {
    // Collect config headers if not already done
    if (!_isFirstFrameReceived) {
      _parseBuffer.addAll(data);
      _extractConfigHeaders();
    }

    // Forward to current player
    if (_isPlayerConnected && _playerSocket != null) {
      try {
        _playerSocket!.add(data);
      } catch (e) {
        logger.w('[VideoProxySession] Failed to push data to player', error: e);
      }
    }
  }

  /// Non-destructive parsing of scrcpy packets to capture config headers
  void _extractConfigHeaders() {
    while (_parseBuffer.length >= 12) {
      // Use ByteData to safely parse headers from the sublist
      final headerBytes = Uint8List.fromList(_parseBuffer.sublist(0, 12));
      final view = ByteData.sublistView(headerBytes);
      final pts = view.getInt64(0, Endian.big);
      final size = view.getUint32(8, Endian.big);

      if (pts == -1) {
        // Metadata / Config packet (SPS/PPS/VPS)
        final totalSize = 12 + size;
        if (_parseBuffer.length >= totalSize) {
          final configPacket = _parseBuffer.sublist(0, totalSize);
          _configHeader.addAll(configPacket);
          _parseBuffer.removeRange(0, totalSize);
          logger.d(
            '[VideoProxySession] Captured Scrcpy Config Packet: $size bytes',
          );
        } else {
          break; // Need more payload bytes
        }
      } else {
        // First real video frame encountered
        logger.i(
          '[VideoProxySession] First video frame detected (PTS: $pts). Stopping header search.',
        );
        _isFirstFrameReceived = true;
        _parseBuffer
            .clear(); // Free memory as we no longer need to parse headers
        break;
      }
    }
  }

  void stop() {
    _streamSubscription?.cancel();
    _playerSocket?.destroy();
    serverSocket?.close();
    _configHeader.clear();
    _parseBuffer.clear();
  }
}

/// Service that manages multiple [VideoProxySession]s.
/// Allows starting and stopping video proxies for different devices.
@lazySingleton
class VideoProxyService {
  // Map of Serial -> Session
  final Map<String, VideoProxySession> _sessions = {};

  Future<int> startProxyFromStream(
    String serial,
    Stream<List<int>> scrcpyStream,
  ) async {
    // Stop existing session for this device
    if (_sessions.containsKey(serial)) {
      _sessions[serial]!.stop();
      _sessions.remove(serial);
    }

    final session = VideoProxySession(scrcpyStream);
    _sessions[serial] = session;

    return await session.start();
  }

  Future<void> stopProxy(String serial) async {
    if (_sessions.containsKey(serial)) {
      _sessions[serial]!.stop();
      _sessions.remove(serial);
    }
  }

  void stopAll() {
    for (final session in _sessions.values) {
      session.stop();
    }
    _sessions.clear();
  }
}
