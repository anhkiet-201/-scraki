import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/scrcpy_options.dart';
import '../datasources/scrcpy_client.dart';
import '../../../../core/utils/logger.dart';

/// Service responsible for managing the scrcpy server on the device.
/// Handles pushing the server JAR, initializing the server with specific options,
/// and cleaning up server processes.
@lazySingleton
class ScrcpyService {
  final Shell _shell;

  ScrcpyService() : _shell = Shell();

  static const _serverAssetPath = 'assets/server/scrcpy-server.jar';
  static const _remoteServerPath = '/data/local/tmp/scrcpy-server.jar';
  static const _serverVersion = '3.3.4';

  Future<String> _getServerPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/scrcpy-server.jar');
      if (!await file.exists()) {
        final byteData = await rootBundle.load(_serverAssetPath);
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }
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

  Future<({int port, String scid})> initServer(
    String deviceSerial,
    ScrcpyOptions options,
    int localPort,
  ) async {
    final client = getIt<ScrcpyClient>();
    final scid = (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF)
        .toRadixString(16)
        .padLeft(8, '0');

    try {
      await pushServer(deviceSerial);
      await client.setupTunnel(deviceSerial, localPort, scid);

      final args = options.toArgs(_serverVersion, scid);

      final command =
          'adb -s $deviceSerial shell CLASSPATH=$_remoteServerPath app_process / com.genymobile.scrcpy.Server ${args.join(' ')}';
      final parts = command.split(' ');
      Process.start(parts.first, parts.sublist(1)).then((p) {
        p.stdout
            .transform(const Utf8Decoder(allowMalformed: true))
            .listen((data) => logger.d('[Scrcpy-OUT] $data'));
        p.stderr
            .transform(const Utf8Decoder(allowMalformed: true))
            .listen((data) => logger.e('[Scrcpy-ERR] $data'));
      });

      await Future<void>.delayed(const Duration(milliseconds: 500));
      return (port: localPort, scid: scid);
    } catch (e) {
      client.removeTunnel(deviceSerial, scid);
      throw ServerException('Failed to init server on $deviceSerial: $e');
    }
  }

  Future<void> killServer(String serial) async {
    try {
      await _shell.run(
        'adb -s $serial shell "ps -en | grep app_process | awk \'{print \$2}\' | xargs kill -9 || true"',
      );
    } catch (e) {
      logger.w(
        '[ScrcpyService] Warning: Failed to kill server on $serial',
        error: e,
      );
    }
  }

  Future<void> pushFiles(String serial, List<String> filePaths) async {
    try {
      for (final path in filePaths) {
        logger.i('[ScrcpyService] Pushing file to $serial: $path');
        // Push to /sdcard/Download/ which is a standard location
        await _shell.run('adb -s $serial push "$path" /sdcard/Download/');

        // Notify MediaScanner to scan the pushed file
        final fileName = path.split(Platform.isWindows ? r'\' : '/').last;
        final uri = 'file:///sdcard/Download/$fileName';
        await _shell.run(
          'adb -s $serial shell am broadcast '
          '-a android.intent.action.MEDIA_SCANNER_SCAN_FILE '
          '-d $uri',
        );
      }
    } catch (e) {
      logger.e('[ScrcpyService] Failed to push files to $serial', error: e);
      rethrow;
    }
  }

  Future<bool> isDeviceConnected(String serial) async {
    try {
      final result = await _shell.run('adb -s $serial get-state');
      return result.outText.trim() == 'device';
    } catch (_) {
      return false;
    }
  }
}
