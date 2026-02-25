import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/adb_binary_service.dart';
import '../../domain/entities/scrcpy_options.dart';
import '../datasources/scrcpy_client.dart';
import '../../../../core/utils/logger.dart';

/// Service responsible for managing the scrcpy server on the device.
/// Handles pushing the server JAR, initializing the server with specific options,
/// and cleaning up server processes.
@lazySingleton
class ScrcpyService {
  final AdbBinaryService _adb;

  ScrcpyService(this._adb);

  final Map<String, Process> _serverProcesses = {};

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
      await _adb.push(deviceSerial, localPath, _remoteServerPath);
    } on AdbException catch (e) {
      throw ServerException(
        'Failed to push server to $deviceSerial: ${e.message}',
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

      // Dùng AdbBinaryService.start để lấy bundled adb path chính xác
      final process = await _adb.start([
        '-s',
        deviceSerial,
        'shell',
        'CLASSPATH=$_remoteServerPath',
        'app_process',
        '/',
        'com.genymobile.scrcpy.Server',
        ...args,
      ]);
      _serverProcesses[deviceSerial] = process;

      process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen((data) => logger.d('[Scrcpy-OUT] $data'));
      process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen((data) => logger.e('[Scrcpy-ERR] $data'));

      process.exitCode.then((code) {
        logger.i('[ScrcpyService] Server process exited with code $code');
        _serverProcesses.remove(deviceSerial);
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
      await _adb.shell(serial, [
        'sh',
        '-c',
        'ps -en | grep app_process | awk \'{print \$2}\' | xargs kill -9 || true',
      ]);

      if (_serverProcesses.containsKey(serial)) {
        logger.i('[ScrcpyService] Killing local adb process for $serial');
        _serverProcesses[serial]?.kill();
        _serverProcesses.remove(serial);
      }
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
        await _adb.push(serial, path, '/sdcard/Download/');

        // Notify MediaScanner
        final fileName = path.split(RegExp(r'[/\\]')).last;
        // Escape literal single-quotes trong filename (POSIX '\'')
        final escapedFileName = fileName.replaceAll("'", "'\\''");
        final uri = 'file:///sdcard/Download/$escapedFileName';
        final scanCmd =
            "am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d '$uri'";

        final scanResult = await _adb.run(['-s', serial, 'shell', scanCmd]);
        if (scanResult.exitCode != 0) {
          logger.w(
            '[ScrcpyService] MediaScanner failed (non-critical): ${scanResult.stderr}',
          );
        }
      }
    } catch (e) {
      logger.e('[ScrcpyService] Failed to push files to $serial', error: e);
      rethrow;
    }
  }

  Future<bool> isDeviceConnected(String serial) async {
    return _adb.isDeviceConnected(serial);
  }
}
