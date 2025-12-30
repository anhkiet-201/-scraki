import 'dart:async';
import 'dart:io';
import 'package:injectable/injectable.dart';

/// Represents a single video proxy session for a device
class VideoProxySession {
  final Stream<List<int>> scrcpyStream;
  ServerSocket? serverSocket;
  StreamSubscription<List<int>>? _streamSubscription;
  Socket? _playerSocket;
  
  // Buffer to hold initial packets (Config SPS/PPS) before player connects
  final List<List<int>> _buffer = [];
  bool _isPlayerConnected = false;

  VideoProxySession(this.scrcpyStream);

  Future<int> start() async {
    // 1. Start listening to Scrcpy stream immediately to capture Config
    _streamSubscription = scrcpyStream.listen(
      (data) {
        if (_isPlayerConnected && _playerSocket != null) {
           try {
             _playerSocket!.add(data);
           } catch (e) {
             print('[VideoProxySession] Error writing to player: $e');
             stop();
           }
        } else {
           // Buffer until player connects
           _buffer.add(data);
        }
      },
      onDone: () {
        print('[VideoProxySession] Scrcpy stream done');
        stop();
      },
      onError: (e) {
        print('[VideoProxySession] Scrcpy stream error: $e');
        stop();
      },
    );

    // 2. Start TCP Server for Native Decoder
    serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    final port = serverSocket!.port;
    print('[VideoProxySession] Listening on port $port');

    serverSocket!.listen((socket) {
      print('[VideoProxySession] Player connected');
      if (_playerSocket != null) {
        _playerSocket!.destroy(); // Only 1 player allowed per session
      }
      
      _playerSocket = socket;
      _playerSocket!.setOption(SocketOption.tcpNoDelay, true);
      _isPlayerConnected = true;

      // Flush buffer
      if (_buffer.isNotEmpty) {
        print('[VideoProxySession] Flushing ${_buffer.length} buffered chunks');
        for (final chunk in _buffer) {
          _playerSocket!.add(chunk);
        }
        _buffer.clear(); 
        // Note: We clear buffer to save memory. 
        // If decoder reconnects, it might miss Config if Scrcpy doesn't resend.
        // But typically reconnect means full restart of Scrcpy session in this architecture.
      }
      
      _playerSocket!.done.then((_) {
         print('[VideoProxySession] Player disconnected');
         _isPlayerConnected = false;
         _playerSocket = null;
      });
    });

    return port;
  }

  void stop() {
    _streamSubscription?.cancel();
    _playerSocket?.destroy();
    serverSocket?.close();
    _buffer.clear();
  }
}

@lazySingleton
class VideoProxyService {
  // Map of Serial -> Session
  final Map<String, VideoProxySession> _sessions = {};

  Future<int> startProxyFromStream(String serial, Stream<List<int>> scrcpyStream) async {
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