import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/exceptions.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:path/path.dart' as p;
import 'package:scraki/features/device/data/datasources/scrcpy_service.dart';
import 'package:scraki/features/device/domain/services/i_tiktok_post_service.dart';

@LazySingleton(as: ITikTokPostService)
class TikTokPostService implements ITikTokPostService {
  final ScrcpyService _scrcpyService;

  TikTokPostService(this._scrcpyService);

  static const _packageNames = {
    TikTokVariant.asia: 'com.ss.android.ugc.trill',
    TikTokVariant.global: 'com.zhiliaoapp.musically',
    TikTokVariant.lite: 'com.zhiliaoapp.musically.go',
  };

  @override
  Future<TikTokVariant?> detectInstalledVariant(String serial) async {
    try {
      final result = await Process.run('adb', [
        '-s',
        serial,
        'shell',
        'pm',
        'list',
        'packages',
      ]);
      final output = result.stdout.toString();

      final lines = output
          .split('\n')
          .map((l) => l.trim().replaceFirst('package:', ''))
          .toList();

      if (lines.contains(_packageNames[TikTokVariant.asia]!)) {
        return TikTokVariant.asia;
      }
      if (lines.contains(_packageNames[TikTokVariant.global]!)) {
        return TikTokVariant.global;
      }
      if (lines.contains(_packageNames[TikTokVariant.lite]!)) {
        return TikTokVariant.lite;
      }

      return null;
    } catch (e) {
      logger.w('[TikTokPostService] Failed to detect TikTok variant', error: e);
      return null;
    }
  }

  @override
  Future<void> openTikTokCreate(String serial, String localVideoPath) async {
    final variant = await detectInstalledVariant(serial);
    if (variant == null) {
      throw AkiRemoteException(
        'Không tìm thấy ứng dụng TikTok trên thiết bị $serial. Vui lòng cài đặt TikTok.',
      );
    }

    final packageName = _packageNames[variant]!;
    final fileName = p.basename(localVideoPath);
    final remoteVideoPath = '/sdcard/Download/$fileName';

    logger.i(
      '[TikTokPostService] Đang đẩy video vào thiết bị $serial và mở TikTok...',
    );

    try {
      // 1. Push file
      await _scrcpyService.pushFiles(serial, [localVideoPath]);

      // Thay thế dấu ' trong tên file cho biến shell (POSX escape)
      final escapedPath = remoteVideoPath.replaceAll("'", "'\\''");
      final uri = "file://'$escapedPath'";

      final shellCmd =
          "am start -a android.intent.action.SEND -t video/mp4 --eu android.intent.extra.STREAM $uri -p $packageName";

      logger.i('[TikTokPostService] Running Intent: $shellCmd');

      // 2. Mở qua ADB share intent
      final result = await Process.run('adb', [
        '-s',
        serial,
        'shell',
        shellCmd,
      ]);

      if (result.stdout.toString().isNotEmpty) {
        logger.i('[TikTokPostService] Shell stdout: ${result.stdout}');
      }
      if (result.stderr.toString().isNotEmpty) {
        logger.w('[TikTokPostService] Shell stderr: ${result.stderr}');
      }

      if (result.exitCode != 0 || result.stderr.toString().contains('Error')) {
        throw Exception(
          'Share intent failed: ${result.stderr.toString().trim().isEmpty ? result.stdout.toString() : result.stderr.toString()}',
        );
      }

      logger.i(
        '[TikTokPostService] Đã gửi lệnh mở màn hình đăng TikTok thành công.',
      );
    } catch (e) {
      logger.e('[TikTokPostService] Lỗi khi mở TikTok Create', error: e);
      throw AkiRemoteException('Không thể mở màn hình đăng TikTok: $e');
    }
  }
}
