import 'dart:async';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/features/device/data/datasources/scrcpy_socket_client.dart';


class VideoStreamController {
  final ScrcpySocketClient _socketClient;

  VideoStreamController() : _socketClient = inject<ScrcpySocketClient>();

  Stream<List<int>> get videoStream => _socketClient.videoStream;

  Future<void> initialize(String serial, int port) async {
    await _socketClient.connect('127.0.0.1', port);
  }

  Future<void> dispose() async {
    await _socketClient.disconnect();
  }
}
