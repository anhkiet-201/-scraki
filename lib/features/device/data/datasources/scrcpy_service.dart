import 'dart:io';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/logger.dart';

/// Service quản lý các thao tác ADB không liên quan đến mirroring:
/// push file lên thiết bị và kiểm tra trạng thái kết nối.
///
/// Chức năng khởi động server scrcpy đã được chuyển sang scrcpy_flutter_plugin.
@lazySingleton
class ScrcpyService {
  ScrcpyService();

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
      final result = await Process.run('adb', ['-s', serial, 'get-state']);
      return (result.stdout as String).trim() == 'device';
    } catch (_) {
      return false;
    }
  }
}
