import 'dart:async';
import '../../core/di/injection.dart';
import '../../data/datasources/scrcpy_socket_client.dart';

class VideoStreamController {
  final ScrcpySocketClient _socketClient;

  // Future: TextureId for Flutter Texture widget
  // int? textureId;

  VideoStreamController() : _socketClient = getIt<ScrcpySocketClient>();

  Stream<List<int>> get videoStream => _socketClient.videoStream;

  Future<void> initialize(String serial, int port) async {
    await _socketClient.connect('127.0.0.1', port);
  }

  Future<void> dispose() async {
    await _socketClient.disconnect();
  }
}
