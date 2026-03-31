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

      // 0. Kill TikTok app trước khi mở share intent
      logger.i('[TikTokPostService] Đang đóng ứng dụng TikTok (nếu đang bật)...');
      await Process.run('adb', [
        '-s',
        serial,
        'shell',
        'am',
        'force-stop',
        packageName,
      ]);

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

  @override
  Future<void> openTikTokPostImages(String serial, String folderPath) async {
    final variant = await detectInstalledVariant(serial);
    if (variant == null) {
      throw AkiRemoteException('TikTok not found on $serial');
    }

    final packageName = _packageNames[variant]!;
    final folderName = p.basename(folderPath);
    logger.i('[TikTokPostService] Posting folder $folderName to $packageName on $serial');

    try {
      // 0. Chuẩn bị Java Wrapper trên thiết bị
      final String localWrapperPath = 'assets/server/tiktok_share.dex';
      final String remoteWrapperPath = '/data/local/tmp/tiktok_share.dex';
      
      logger.i('[TikTokPostService] Đang đẩy Java Wrapper lên thiết bị...');
      await Process.run('adb', [
        '-s', 
        serial, 
        'push', 
        localWrapperPath, 
        remoteWrapperPath
      ]);

      // 0.1 Kill TikTok
      await Process.run('adb', ['-s', serial, 'shell', 'am', 'force-stop', packageName]);
      
      // Đợi một chút để App giải phóng tài nguyên
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 1. Khôi phục về Download (Nơi ổn định nhất cho việc share file)
      final remoteBaseDir = '/sdcard/Download/';
      final pushResult = await Process.run('adb', [
        '-s',
        serial,
        'push',
        folderPath,
        remoteBaseDir,
      ]);

      if (pushResult.exitCode != 0) {
        throw Exception('adb push directory failed: ${pushResult.stderr}');
      }

      await Process.run('adb', [
        '-s',
        serial,
        'shell',
        'am',
        'broadcast',
        '--user',
        '0',
        '-a',
        'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
        '-d',
        'file://$remoteBaseDir$folderName',
      ]);

      // 2. Liệt kê ảnh locally để tạo URIs trỏ đúng vào thư mục con trên Android
      final dir = Directory(folderPath);
      final imageFiles = dir.listSync()
          .whereType<File>()
          .where((f) {
            final ext = p.extension(f.path).toLowerCase();
            return const {'.png', '.jpg', '.jpeg', '.webp'}.contains(ext);
          })
          .map((f) => p.basename(f.path))
          .toList();
      
      // Sắp xếp để đúng thứ tự slide
      imageFiles.sort((a, b) => a.compareTo(b));

      if (imageFiles.isEmpty) {
        throw Exception('Thư mục không chứa ảnh hợp lệ.');
      }

      // 2.7 Truy vấn Content URI theo lô (Batch Query) bằng bucket_display_name
      logger.i('[TikTokPostService] Đang truy vấn IDs cho toàn bộ thư mục $folderName...');
      final queryResult = await Process.run('adb', [
        '-s',
        serial,
        'shell',
        'content',
        'query',
        '--user',
        '0',
        '--uri',
        'content://media/external/images/media',
        '--projection',
        '_id:_display_name',
        '--where',
        "bucket_display_name='$folderName'",
      ]);

      final Map<String, String> nameToIdMap = {};
      if (queryResult.exitCode == 0 && queryResult.stdout.toString().isNotEmpty) {
        final lines = queryResult.stdout.toString().split('\n');
        for (final line in lines) {
          final idMatch = RegExp(r'_id=(\d+)').firstMatch(line);
          final nameMatch = RegExp(r'_display_name=([^,\s]+)').firstMatch(line);
          if (idMatch != null && nameMatch != null) {
            nameToIdMap[nameMatch.group(1)!] = idMatch.group(1)!;
          }
        }
      }

      final List<String> contentUris = [];
      for (final fileName in imageFiles) {
        if (nameToIdMap.containsKey(fileName)) {
          contentUris.add('content://media/external/images/media/${nameToIdMap[fileName]}');
        } else {
          // Fallback nếu không thấy ID
          final remotePath = '$remoteBaseDir$folderName/$fileName';
          contentUris.add('file://$remotePath');
        }
      }

      logger.i('[TikTokPostService] Đã ánh xạ được ${contentUris.where((u) => u.startsWith('content')).length}/${imageFiles.length} URIs.');

      final String finalUriString = contentUris.join(',');
      final String wrapperCmd = 'CLASSPATH=/data/local/tmp/tiktok_share.dex app_process /system/bin TikTokShareWrapper $packageName "$finalUriString"';
      
      logger.i('[TikTokPostService] Đang thực thi Java Intent Wrapper...');
      
      final result = await Process.run('adb', [
        '-s', serial, 'shell', wrapperCmd,
      ]);

      if (result.exitCode != 0 || result.stderr.toString().contains('Error')) {
        throw Exception('Java Wrapper thất bại: ${result.stderr}');
      }

      logger.i('[TikTokPostService] Đăng bộ ảnh thành công thông qua Java Wrapper.');
    } catch (e) {
      logger.e('[TikTokPostService] Lỗi khi xử lý bộ ảnh', error: e);
      throw AkiRemoteException('Lỗi hệ thống khi đăng bộ ảnh: $e');
    }
  }
}
