import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/exceptions.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:path/path.dart' as p;
import 'package:scraki/features/device/data/datasources/scrcpy_service.dart';
import 'package:scraki/features/device/domain/services/i_facebook_post_service.dart';

@LazySingleton(as: IFacebookPostService)
class FacebookPostService implements IFacebookPostService {
  final ScrcpyService _scrcpyService;

  FacebookPostService(this._scrcpyService);

  static const _packageName = 'com.facebook.katana';

  @override
  Future<bool> isFacebookInstalled(String serial) async {
    try {
      final result = await Process.run('adb', [
        '-s',
        serial,
        'shell',
        'pm',
        'list',
        'packages',
        _packageName,
      ]);
      return result.stdout.toString().contains('package:$_packageName');
    } catch (e) {
      logger.w('[FacebookPostService] Failed to check if Facebook is installed', error: e);
      return false;
    }
  }

  @override
  Future<void> openFacebookCreate(
    String serial,
    String localVideoPath, {
    required FacebookPostTarget target,
  }) async {
    final installed = await isFacebookInstalled(serial);
    if (!installed) {
      throw AkiRemoteException(
        'Không tìm thấy ứng dụng Facebook trên thiết bị $serial. Vui lòng cài đặt Facebook.',
      );
    }

    final fileName = p.basename(localVideoPath);
    final remoteVideoPath = '/sdcard/Download/$fileName';

    logger.i(
      '[FacebookPostService] Đang đẩy video vào thiết bị $serial và mở Facebook...',
    );

    try {
      // 0. Kill Facebook app trước khi mở share intent
      logger.i('[FacebookPostService] Đang đóng ứng dụng Facebook (nếu đang bật)...');
      await Process.run('adb', [
        '-s',
        serial,
        'shell',
        'am',
        'force-stop',
        _packageName,
      ]);

      // 1. Push file
      await _scrcpyService.pushFiles(serial, [localVideoPath]);

      // Thay thế dấu ' trong tên file cho biến shell (POSIX escape)
      final escapedPath = remoteVideoPath.replaceAll("'", "'\\''");
      final uri = "file://'$escapedPath'";

      final String activityName;
      switch (target) {
        case FacebookPostTarget.feed:
          activityName = 'com.facebook.composer.shareintent.ImplicitShareIntentHandlerDefaultAlias';
          break;
        case FacebookPostTarget.group:
          activityName = 'com.facebook.composer.shareintent.ShareToGroupsAlias';
          break;
        case FacebookPostTarget.reels:
          activityName = 'com.facebook.inspiration.fbshorts.shareintent.InpirationFbShortsShareAlias';
          break;
      }

      final ext = fileName.toLowerCase().split('.').last;
      final String mimeType;
      if (const {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'ts', 'm4v', 'flv', 'wmv'}.contains(ext)) {
        mimeType = 'video/mp4';
      } else {
        mimeType = 'image/*';
      }

      final shellCmd =
          "am start -n $_packageName/$activityName -a android.intent.action.SEND -t $mimeType --eu android.intent.extra.STREAM $uri";

      logger.i('[FacebookPostService] Running Intent: $shellCmd');

      // 2. Mở qua ADB share intent
      final result = await Process.run('adb', [
        '-s',
        serial,
        'shell',
        shellCmd,
      ]);

      if (result.stdout.toString().isNotEmpty) {
        logger.i('[FacebookPostService] Shell stdout: ${result.stdout}');
      }
      if (result.stderr.toString().isNotEmpty) {
        logger.w('[FacebookPostService] Shell stderr: ${result.stderr}');
      }

      if (result.exitCode != 0 || result.stderr.toString().contains('Error')) {
        throw Exception(
          'Share intent failed: ${result.stderr.toString().trim().isEmpty ? result.stdout.toString() : result.stderr.toString()}',
        );
      }

      logger.i(
        '[FacebookPostService] Đã gửi lệnh mở màn hình đăng Facebook thành công.',
      );
    } catch (e) {
      logger.e('[FacebookPostService] Lỗi khi mở Facebook Create', error: e);
      throw AkiRemoteException('Không thể mở màn hình đăng Facebook: $e');
    }
  }

  @override
  Future<void> openFacebookPostImages(String serial, String folderPath) async {
    final installed = await isFacebookInstalled(serial);
    if (!installed) {
      throw AkiRemoteException('Không tìm thấy ứng dụng Facebook trên thiết bị $serial.');
    }

    final folderName = p.basename(folderPath);
    logger.i('[FacebookPostService] Posting folder $folderName to $_packageName on $serial');

    try {
      // 0. Chuẩn bị Java Wrapper trên thiết bị
      final String localWrapperPath = 'assets/server/tiktok_share.dex';
      final String remoteWrapperPath = '/data/local/tmp/tiktok_share.dex';
      
      logger.i('[FacebookPostService] Đang đẩy Java Wrapper lên thiết bị...');
      await Process.run('adb', [
        '-s', 
        serial, 
        'push', 
        localWrapperPath, 
        remoteWrapperPath
      ]);

      // 0.1 Kill Facebook
      await Process.run('adb', ['-s', serial, 'shell', 'am', 'force-stop', _packageName]);
      
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 1. Khôi phục về Download
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

      // 2. Liệt kê ảnh locally
      final dir = Directory(folderPath);
      final imageFiles = dir.listSync()
          .whereType<File>()
          .where((f) {
            final ext = p.extension(f.path).toLowerCase();
            return const {'.png', '.jpg', '.jpeg', '.webp'}.contains(ext);
          })
          .map((f) => p.basename(f.path))
          .toList();
      
      imageFiles.sort((a, b) => a.compareTo(b));

      if (imageFiles.isEmpty) {
        throw Exception('Thư mục không chứa ảnh hợp lệ.');
      }

      // 2.7 Truy vấn Content URI theo lô
      logger.i('[FacebookPostService] Đang truy vấn IDs cho toàn bộ thư mục $folderName...');
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
          final remotePath = '$remoteBaseDir$folderName/$fileName';
          contentUris.add('file://$remotePath');
        }
      }

      logger.i('[FacebookPostService] Đã ánh xạ được ${contentUris.where((u) => u.startsWith('content')).length}/${imageFiles.length} URIs.');

      final String finalUriString = contentUris.join(',');
      final String wrapperCmd = 'CLASSPATH=/data/local/tmp/tiktok_share.dex app_process /system/bin TikTokShareWrapper $_packageName "$finalUriString"';
      
      logger.i('[FacebookPostService] Đang thực thi Java Intent Wrapper cho Facebook...');
      
      final result = await Process.run('adb', [
        '-s', serial, 'shell', wrapperCmd,
      ]);

      if (result.exitCode != 0 || result.stderr.toString().contains('Error')) {
        throw Exception('Java Wrapper thất bại: ${result.stderr}');
      }

      logger.i('[FacebookPostService] Đăng bộ ảnh Facebook thành công thông qua Java Wrapper.');
    } catch (e) {
      logger.e('[FacebookPostService] Lỗi khi xử lý bộ ảnh', error: e);
      throw AkiRemoteException('Lỗi hệ thống khi đăng bộ ảnh lên Facebook: $e');
    }
  }
}
