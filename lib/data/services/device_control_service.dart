import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import '../utils/scrcpy_input_serializer.dart';
import 'scrcpy_service.dart';

@lazySingleton
class DeviceControlService {
  final ScrcpyService _scrcpyService;
  final Map<String, Socket> _activeSockets = {};

  DeviceControlService(this._scrcpyService);

  /// Establishes a raw TCP connection intended for sending control bytes.
  Future<void> connectControlSocket(String serial, int port) async {
    // Check if valid serial context (optional)
    // Close existing if any
    if (_activeSockets.containsKey(serial)) {
      await dispose(serial);
    }

    try {
      final socket = await Socket.connect('127.0.0.1', port);
      socket.setOption(SocketOption.tcpNoDelay, true);
      _activeSockets[serial] = socket;
      print('Control Socket connected for device $serial on port $port');
    } catch (e) {
      throw ConnectionFailure('Failed to connect control socket: $e');
    }
  }

  /// Sends a serialized touch message to the device
  void sendTouch(String serial, TouchControlMessage message) {
    final socket = _activeSockets[serial];
    if (socket == null) {
      print('Warning: No active control socket for $serial');
      // Optionally try to reconnect if we knew the port?
      // For now, just return.
      return;
    }

    try {
      final data = message.serialize();
      socket.add(data);
      socket.flush(); // Ensure immediate transmission
    } catch (e) {
      print('Error sending touch event to $serial: $e');
      dispose(serial);
    }
  }

  Future<void> dispose(String serial) async {
    final socket = _activeSockets.remove(serial);
    if (socket != null) {
      try {
        await socket.close();
      } catch (e) {
        // Ignore close errors
      }
    }
  }
}
