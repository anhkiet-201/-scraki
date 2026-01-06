import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../datasources/scrcpy_header.dart';
import '../datasources/scrcpy_protocol_parser.dart';
import '../../../../core/utils/logger.dart';

@lazySingleton
class ScrcpySocketClient {
  Socket? _socket;
  StreamSubscription<List<int>>? _subscription;
  final _streamController = StreamController<List<int>>.broadcast();

  // Expose header for coordinate scaling
  ScrcpyHeader? _header;
  ScrcpyHeader? get header => _header;

  Stream<List<int>> get videoStream => _streamController.stream;

  /// Sends binary data to the socket
  void send(List<int> data) {
    if (_socket == null) {
      // It's possible we are not connected or socket closed.
      // For UI "fire and forget" control events, we might just log or ignore.
      // But let's log.
      logger.w('Warning: Attempted to send data but socket is null.');
      return;
    }
    try {
      _socket!.add(data);
    } catch (e) {
      logger.e('Error sending data', error: e);
    }
  }

  Future<void> connect(String host, int port) async {
    try {
      _socket = await Socket.connect(host, port);
      _socket!.setOption(SocketOption.tcpNoDelay, true);

      final completer = Completer<void>();
      final buffer = <int>[];
      bool headerParsed = false;
      _header = null;

      _subscription = _socket!.listen(
        (data) {
          if (!headerParsed) {
            buffer.addAll(data);
            if (buffer.length >= 69) {
              try {
                final headerData = Uint8List.fromList(buffer);
                _header = ScrcpyProtocolParser.parseHeader(headerData);

                logger.i(
                  'Device Connected: ${_header!.deviceName} (${_header!.width}x${_header!.height})',
                );
                headerParsed = true;
                completer.complete();

                // Yield remaining bytes (video stream)
                if (buffer.length > 69) {
                  _streamController.add(buffer.sublist(69));
                }
              } catch (e) {
                if (!completer.isCompleted) {
                  completer.completeError(
                    ConnectionFailure('Handshake failed: $e'),
                  );
                }
                disconnect();
              }
            }
          } else {
            _streamController.add(data);
          }
        },
        onError: (Object error) {
          final failure = ConnectionFailure(error.toString());
          if (!completer.isCompleted) {
            completer.completeError(failure);
          }
          _streamController.addError(failure);
        },
        onDone: () {
          _streamController.close();
        },
      );

      return completer.future;
    } on SocketException catch (e) {
      throw ConnectionFailure('Socket connection failed: ${e.message}');
    } catch (e) {
      throw ConnectionFailure('Unexpected error: $e');
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _socket?.close();
    await _streamController.close();
    _socket = null;
    _header = null;
  }
}
