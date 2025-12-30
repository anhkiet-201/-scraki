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

  /// Sets the control socket for a specific device (used in reverse tunnel mode).
  void setControlSocket(String serial, Socket socket) {
    if (_activeSockets.containsKey(serial)) {
      dispose(serial);
    }
    
    socket.setOption(SocketOption.tcpNoDelay, true);
    _activeSockets[serial] = socket;
    print('[DeviceControlService] Control Socket set for device $serial');
    
    // Listen to the socket to detect closure, even if we only write to it.
    socket.listen(
      (data) {
         // Scrcpy might send clipboard data or other control messages back.
         // For now, we just ignore or log.
         print('[ControlSocket] Received ${data.length} bytes from $serial');
      },
      onDone: () {
        print('[ControlSocket] Socket closed for $serial');
        _activeSockets.remove(serial);
      },
      onError: (e) {
        print('[ControlSocket] Error on socket for $serial: $e');
        _activeSockets.remove(serial);
      },
    );
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
