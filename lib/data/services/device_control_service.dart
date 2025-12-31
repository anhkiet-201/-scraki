import 'dart:io';
import 'package:injectable/injectable.dart';
import '../utils/scrcpy_input_serializer.dart';
import '../../core/utils/logger.dart';

/// Service responsible for managing control sockets for devices.
/// Handles sending input events (touch, key, scroll) to the scrcpy server on the device.
@lazySingleton
class DeviceControlService {
  final Map<String, Socket> _activeSockets = {};

  DeviceControlService();

  /// Sets the control socket for a specific device (used in reverse tunnel mode).
  void setControlSocket(String serial, Socket socket) {
    if (_activeSockets.containsKey(serial)) {
      dispose(serial);
    }

    socket.setOption(SocketOption.tcpNoDelay, true);
    _activeSockets[serial] = socket;
    logger.i('[DeviceControlService] Control Socket set for device $serial');

    // Listen to the socket to detect closure, even if we only write to it.
    socket.listen(
      (data) {
        // Scrcpy might send clipboard data or other control messages back.
        // For now, we just ignore or log.
        logger.d('[ControlSocket] Received ${data.length} bytes from $serial');
      },
      onDone: () {
        logger.i('[ControlSocket] Socket closed for $serial');
        _activeSockets.remove(serial);
      },
      onError: (Object e) {
        logger.e('[ControlSocket] Error on socket for $serial', error: e);
        _activeSockets.remove(serial);
      },
    );
  }

  /// Sends a serialized control message (Touch, Key, etc.) to the device
  void sendControlMessage(String serial, ControlMessage message) {
    final socket = _activeSockets[serial];
    if (socket == null) {
      logger.w('Warning: No active control socket for $serial');
      // Optionally try to reconnect if we knew the port?
      // For now, just return.
      return;
    }

    try {
      final data = message.serialize();
      socket.add(data);
      // socket.flush() is not needed with tcpNoDelay and causes overhead
    } catch (e) {
      logger.e('Error sending control message to $serial', error: e);
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
