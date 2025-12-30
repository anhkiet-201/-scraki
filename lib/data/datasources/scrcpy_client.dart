import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:process_run/shell.dart';
import '../../core/error/exceptions.dart';
import '../../core/protocol/scrcpy_header.dart';
import '../../core/protocol/scrcpy_protocol_parser.dart';

class ScrcpySession {
  final ScrcpyHeader header;
  final Stream<List<int>> videoStream;
  final Socket socket;
  
  ScrcpySession({
    required this.header, 
    required this.videoStream,
    required this.socket,
  });
}

@lazySingleton
class ScrcpyClient {
  final Shell _shell;

  ScrcpyClient() : _shell = Shell();

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

  /// Parse header from an already-connected socket and return a session with stream
  Future<ScrcpySession> parseHeaderFromSocket(Socket socket) async {
    try {
      socket.setOption(SocketOption.tcpNoDelay, true);
      print('[ScrcpyClient] Parsing header from connected socket...');

      final completer = Completer<ScrcpySession>();
      final buffer = <int>[];
      bool headerParsed = false;
      
      // Use a single-subscription controller so it buffers events until listened to.
      // This is crucial because we might receive the Config Packet immediately after the header,
      // before the caller (DeviceStore -> VideoProxyService) has a chance to subscribe.
      final controller = StreamController<List<int>>();

      // We need to keep subscription alive, so we don't cancel it inside the function.
      // The controller's stream is what the UI/Proxy will listen to.
      // We'll hook the socket to the controller.
      
      socket.listen(
        (data) {
          if (!headerParsed) {
            buffer.addAll(data);
            if (buffer.length >= ScrcpyProtocolParser.headerSize) {
              try {
                print('[ScrcpyClient] Parsing header...');
                final headerData = Uint8List.fromList(buffer);
                final header = ScrcpyProtocolParser.parseHeader(headerData);
                headerParsed = true;
                print(
                  '[ScrcpyClient] Header parsed successfully: ${header.deviceName} ${header.width}x${header.height}',
                );
                
                // Create session object
                final session = ScrcpySession(
                  header: header,
                  videoStream: controller.stream,
                  socket: socket
                );
                
                completer.complete(session);

                // Forward any remaining bytes (video data) to the stream
                if (buffer.length > ScrcpyProtocolParser.headerSize) {
                  print(
                    '[ScrcpyClient] Forwarding ${buffer.length - ScrcpyProtocolParser.headerSize} bytes of video data',
                  );
                  controller.add(
                    buffer.sublist(ScrcpyProtocolParser.headerSize),
                  );
                }
              } catch (e) {
                print('[ScrcpyClient] Error parsing header: $e');
                if (!completer.isCompleted) completer.completeError(e);
                socket.destroy();
                controller.close();
              }
            }
          } else {
            // Forward directly to stream
            controller.add(data);
          }
        },
        onError: (Object e) {
          print('[ScrcpyClient] Socket error: $e');
          if (!completer.isCompleted) completer.completeError(e);
          controller.addError(e);
        },
        onDone: () {
          print('[ScrcpyClient] Socket closed');
          controller.close();
        },
      );

      // Add timeout for header only
      return completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print(
            '[ScrcpyClient] Timeout waiting for header. Buffer size: ${buffer.length}',
          );
          socket.destroy();
          controller.close();
          throw ServerException('Timeout waiting for Scrcpy header');
        },
      );
    } catch (e) {
      print('[ScrcpyClient] Failed to parse header: $e');
      throw ServerException('Failed to parse Scrcpy header: $e');
    }
  }
}