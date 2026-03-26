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
      final process = await Process.start(parts.first, parts.sublist(1));
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
      await _shell.run(
        'adb -s $serial shell "ps -en | grep app_process | awk \'{print \$2}\' | xargs kill -9 || true"',
      );

      // Kill local adb process if tracked
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

  Future<void> pushFiles(
    String serial,
    List<String> filePaths, {
    void Function(double progress)? onProgress,
  }) async {
    // adb push ghi tiến trình ra stderr: "[ 50%] /sdcard/Download/file.mp4"
    final progressRegex = RegExp(r'\[\s*(\d+)%\]');
    final total = filePaths.length;

    try {
      for (int i = 0; i < total; i++) {
        final path = filePaths[i];
        final fileBaseProgress = i / total;
        final fileRangeSize = 1.0 / total;

        logger.i('[ScrcpyService] Pushing file ${i + 1}/$total: $path');

        final pushProcess = await Process.start('adb', [
          '-s', serial, 'push', path, '/sdcard/Download/',
        ]);

        final stderrBuf = StringBuffer();

        // Stream stderr: parse "[XX%] filename"
        pushProcess.stderr
            .transform<String>(utf8.decoder)
            .listen((String chunk) {
          stderrBuf.write(chunk);
          for (final part in chunk.split(RegExp(r'[\r\n]'))) {
            final match = progressRegex.firstMatch(part);
            if (match != null) {
              final percent = int.tryParse(match.group(1) ?? '') ?? 0;
              // Progress tổng = tiến trình file hiện tại trong range của nó
              final overall = fileBaseProgress + (percent / 100.0) * fileRangeSize;
              onProgress?.call(overall.clamp(0.0, 1.0));
            }
          }
        });

        // Drain stdout
        pushProcess.stdout.drain<void>();

        final exitCode = await pushProcess.exitCode;
        if (exitCode != 0) {
          throw Exception('adb push failed: ${stderrBuf.toString()}');
        }

        // Notify MediaScanner
        final fileName = path.split(RegExp(r'[/\\]')).last;
        final escapedFileName = fileName.replaceAll("'", "'\\''");
        final uri = 'file:///sdcard/Download/$escapedFileName';
        final scanResult = await Process.run('adb', [
          '-s', serial, 'shell',
          "am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d '$uri'",
        ]);
        if (scanResult.exitCode != 0) {
          logger.w('[ScrcpyService] MediaScanner failed: ${scanResult.stderr}');
        }
      }

      // Đảm bảo progress đạt 100% sau khi xong
      onProgress?.call(1.0);
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
