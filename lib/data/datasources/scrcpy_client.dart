import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:process_run/shell.dart';
import '../../core/error/exceptions.dart';
import '../../core/protocol/scrcpy_header.dart';
import '../../core/protocol/scrcpy_protocol_parser.dart';

@lazySingleton
class ScrcpyClient {
  final Shell _shell;
  Socket? _socket;
  StreamSubscription<List<int>>? _subscription;

  // StreamController needs to be recreatable since singleton may be reused
  StreamController<List<int>>? _streamController;

  StreamController<List<int>> get _controller {
    if (_streamController == null || _streamController!.isClosed) {
      _streamController = StreamController<List<int>>.broadcast();
    }
    return _streamController!;
  }

  ScrcpyClient() : _shell = Shell();

  Stream<List<int>> get videoStream {
    print(
      '[ScrcpyClient] videoStream getter called. Controller isClosed: ${_streamController?.isClosed}',
    );
    return _controller.stream;
  }

  /// Sets up ADB reverse tunnel: adb reverse localabstract:scrcpy_$scid tcp:localPort
  Future<void> setupTunnel(String serial, int localPort, String scid) async {
    try {
      // With tunnel_forward=true, server connects to 'scrcpy_<scid>'
      await _shell.run(
        'adb -s $serial reverse localabstract:scrcpy_$scid tcp:$localPort',
      );
      // Also setup 'scrcpy' as fallback name just in case
      await _shell.run(
        'adb -s $serial reverse localabstract:scrcpy tcp:$localPort',
      );
      print(
        '[ScrcpyClient] Reverse tunnel setup for scrcpy_$scid on port $localPort',
      );
    } catch (e) {
      throw ServerException('Failed to setup ADB reverse tunnel: $e');
    }
  }

  /// Removes ADB reverse tunnel
  Future<void> removeTunnel(String serial, int localPort) async {
    try {
      await _shell.run('adb -s $serial reverse --remove-all');
    } catch (_) {
      // Ignore cleanup errors
    }
  }

  /// Connects to the forwarded local port and authenticates (reads header)
  Future<ScrcpyHeader> connect(int localPort) async {
    try {
      // Cleanup previous session if any
      await disconnect();

      print('[ScrcpyClient] Connecting to 127.0.0.1:$localPort...');
      _socket = await Socket.connect('127.0.0.1', localPort);
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      print('[ScrcpyClient] Socket connected, waiting for header...');

      final completer = Completer<ScrcpyHeader>();
      final buffer = <int>[];
      bool headerParsed = false;

      _subscription = _socket!.listen(
        (data) {
          // print(
          //   '[ScrcpyClient] Received ${data.length} bytes. Buffer size: ${buffer.length}',
          // );
          if (!headerParsed) {
            buffer.addAll(data);
            print(
              '[ScrcpyClient] Buffer now has ${buffer.length} bytes (need ${ScrcpyProtocolParser.headerSize})',
            );
            if (buffer.length >= ScrcpyProtocolParser.headerSize) {
              try {
                print('[ScrcpyClient] Parsing header...');
                final headerData = Uint8List.fromList(buffer);
                final header = ScrcpyProtocolParser.parseHeader(headerData);
                headerParsed = true;
                print(
                  '[ScrcpyClient] Header parsed successfully: ${header.deviceName} ${header.width}x${header.height}',
                );
                completer.complete(header);

                // Forward any remaining bytes (video data) to the stream
                if (buffer.length > ScrcpyProtocolParser.headerSize) {
                  print(
                    '[ScrcpyClient] Forwarding ${buffer.length - ScrcpyProtocolParser.headerSize} bytes of video data',
                  );
                  _controller.add(
                    buffer.sublist(ScrcpyProtocolParser.headerSize),
                  );
                }
              } catch (e) {
                print('[ScrcpyClient] Error parsing header: $e');
                if (!completer.isCompleted) completer.completeError(e);
                disconnect();
              }
            }
          } else {
            // Forward directly to stream
            _controller.add(data);
          }
        },
        onError: (Object e) {
          print('[ScrcpyClient] Socket error: $e');
          if (!completer.isCompleted) completer.completeError(e);
          _controller.addError(e);
        },
        onDone: () {
          print('[ScrcpyClient] Socket closed');
          _controller.close();
        },
      );

      // Add timeout
      return completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print(
            '[ScrcpyClient] Timeout waiting for header. Buffer size: ${buffer.length}',
          );
          disconnect();
          throw ServerException('Timeout waiting for Scrcpy header');
        },
      );
    } catch (e) {
      print('[ScrcpyClient] Connection failed: $e');
      throw ServerException('Failed to connect to Scrcpy server: $e');
    }
  }

  /// Parse header from an already-connected socket
  Future<ScrcpyHeader> parseHeaderFromSocket(Socket socket) async {
    try {
      // Cleanup previous session if any (except the socket we just got)
      await _subscription?.cancel();
      _subscription = null;
      if (_socket != null && _socket != socket) {
        await _socket!.close();
      }

      _socket = socket;
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      print('[ScrcpyClient] Parsing header from connected socket...');

      final completer = Completer<ScrcpyHeader>();
      final buffer = <int>[];
      bool headerParsed = false;

      _subscription = _socket!.listen(
        (data) {
          // print(
          //   '[ScrcpyClient] Received ${data.length} bytes. Buffer size: ${buffer.length}',
          // );
          if (!headerParsed) {
            buffer.addAll(data);
            print(
              '[ScrcpyClient] Buffer now has ${buffer.length} bytes (need ${ScrcpyProtocolParser.headerSize})',
            );
            if (buffer.length >= ScrcpyProtocolParser.headerSize) {
              try {
                print('[ScrcpyClient] Parsing header...');
                final headerData = Uint8List.fromList(buffer);
                final header = ScrcpyProtocolParser.parseHeader(headerData);
                headerParsed = true;
                print(
                  '[ScrcpyClient] Header parsed successfully: ${header.deviceName} ${header.width}x${header.height}',
                );
                completer.complete(header);

                // Forward any remaining bytes (video data) to the stream
                if (buffer.length > ScrcpyProtocolParser.headerSize) {
                  print(
                    '[ScrcpyClient] Forwarding ${buffer.length - ScrcpyProtocolParser.headerSize} bytes of video data',
                  );
                  _controller.add(
                    buffer.sublist(ScrcpyProtocolParser.headerSize),
                  );
                }
              } catch (e) {
                print('[ScrcpyClient] Error parsing header: $e');
                if (!completer.isCompleted) completer.completeError(e);
                disconnect();
              }
            }
          } else {
            // Forward directly to stream
            _controller.add(data);
          }
        },
        onError: (Object e) {
          print('[ScrcpyClient] Socket error: $e');
          if (!completer.isCompleted) completer.completeError(e);
          _controller.addError(e);
        },
        onDone: () {
          print('[ScrcpyClient] Socket closed');
          _controller.close();
        },
      );

      // Add timeout
      return completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print(
            '[ScrcpyClient] Timeout waiting for header. Buffer size: ${buffer.length}',
          );
          disconnect();
          throw ServerException('Timeout waiting for Scrcpy header');
        },
      );
    } catch (e) {
      print('[ScrcpyClient] Failed to parse header: $e');
      throw ServerException('Failed to parse Scrcpy header: $e');
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _socket?.close();
    await _controller.close();
  }
}
