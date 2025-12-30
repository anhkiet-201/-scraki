import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';
import '../../core/di/injection.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/scrcpy_options.dart';
import '../datasources/scrcpy_client.dart';

@lazySingleton
class ScrcpyService {
  final Shell _shell;
  final Map<String, int> _devicePorts = {};
  // Port is now passed dynamically

  ScrcpyService() : _shell = Shell();

  /// Constants
  static const _serverAssetPath = 'assets/server/scrcpy-server.jar';
  static const _remoteServerPath = '/data/local/tmp/scrcpy-server.jar';
  static const _serverVersion = '3.3.4';

  Future<String> _getServerPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/scrcpy-server.jar');

      // Always copy from assets to ensure latest version (no caching)
      final byteData = await rootBundle.load(_serverAssetPath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file.path;
    } catch (e) {
      throw ServerException('Failed to copy scrcpy-server.jar: $e');
    }
  }

  Future<void> pushServer(String deviceSerial) async {
    try {
      final localPath = await _getServerPath();
      await _shell.run(
        'adb -s $deviceSerial push $localPath $_remoteServerPath',
      );
    } catch (e) {
      throw ServerException('Failed to push server to $deviceSerial: $e');
    }
  }

  /// Initializes the server process and tunnel, returning the local port.
  /// Does NOT connect the socket yet.
  Future<int> initServer(
    String deviceSerial,
    ScrcpyOptions options,
    int localPort,
  ) async {
    if (_devicePorts.containsKey(deviceSerial)) {
      return _devicePorts[deviceSerial]!;
    }

    _devicePorts[deviceSerial] = localPort;

    final client = getIt<ScrcpyClient>();

    try {
      // 0. Push Server
      await pushServer(deviceSerial);

      // 1. Build arguments and setup tunnel (Key=Value for v2.0+)
      // Note: scrcpy-server.jar expects the client version first, then options.
      final scid = (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF)
          .toRadixString(16)
          .padLeft(8, '0');

      // Setup Tunnel with SCID and localPort
      await client.setupTunnel(deviceSerial, localPort, scid);

      final args = [
        _serverVersion,
        'scid=$scid',
        'log_level=debug', // Changed to debug for more verbose logs
        'audio=false',
        'video_codec=h265', // Switched from h264 to h265
        if (options.maxSize > 0) 'max_size=${options.maxSize}',
        'video_bit_rate=4000000', // Reduced from 8Mbps to 4Mbps for lower latency
        if (options.maxFps > 0) 'max_fps=${options.maxFps}',
        'tunnel_forward=false',
        'control=false',
        'cleanup=true',
        // Essential meta options
        'send_device_meta=true',
        'send_frame_meta=true',
        'send_codec_meta=true',
      ];

      final command =
          'adb -s $deviceSerial shell CLASSPATH=$_remoteServerPath app_process / com.genymobile.scrcpy.Server ${args.join(' ')}';

      print('[ANTIGRAVITY-DEBUG] Scrcpy options: ${args.join(' ')}');
      print('[ANTIGRAVITY] Starting Scrcpy Server: $command');

      // 3. Start Server Process
      final parts = command.split(' ');
      Process.start(parts.first, parts.sublist(1)).then((p) {
        // Use utf8.decoder to properly decode logs
        p.stdout.transform(utf8.decoder).listen((data) {
          print('[Scrcpy-OUT] $data');
        });
        p.stderr.transform(utf8.decoder).listen((data) {
          print('[Scrcpy-ERR] $data');
          if (data.contains('Aborted') ||
              data.contains('Exception') ||
              data.contains('Error')) {
            print('Critical error from scrcpy-server. Capturing logcat...');
            _shell.run('adb -s $deviceSerial logcat -d -t 100').then((results) {
              for (final res in results) {
                print('[LOGCAT] ${res.stdout}');
              }
            });
          }
        });
      });

      // Wait for server to be ready to accept connections
      await Future.delayed(const Duration(milliseconds: 1500));

      return localPort;
    } catch (e) {
      client.removeTunnel(deviceSerial, localPort);
      _devicePorts.remove(deviceSerial);
      throw ServerException('Failed to init server on $deviceSerial: $e');
    }
  }

  int? getForwardPort(String serial) => _devicePorts[serial];
}
