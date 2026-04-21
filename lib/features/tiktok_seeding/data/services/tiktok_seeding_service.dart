import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/exceptions.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/domain/services/i_tiktok_post_service.dart';
import 'package:scraki/features/tiktok_seeding/domain/services/i_tiktok_seeding_service.dart';

@LazySingleton(as: ITikTokSeedingService)
class TikTokSeedingService implements ITikTokSeedingService {
  final ITikTokPostService _tiktokPostService;

  TikTokSeedingService(this._tiktokPostService);

  static const _schemes = {
    TikTokVariant.asia: 'snssdk1180',
    TikTokVariant.global: 'snssdk1233',
    TikTokVariant.lite: 'snssdk1180',
  };

  static const _packageNames = {
    TikTokVariant.asia: 'com.ss.android.ugc.trill',
    TikTokVariant.global: 'com.zhiliaoapp.musically',
    TikTokVariant.lite: 'com.zhiliaoapp.musically.go',
  };

  @override
  Future<void> openSearch(String serial, String query) async {
    final variant = await _tiktokPostService.detectInstalledVariant(serial);
    
    if (variant == null) {
      throw AkiRemoteException(
        'Không tìm thấy ứng dụng TikTok trên thiết bị $serial.',
      );
    }

    final scheme = _schemes[variant]!;
    final packageName = _packageNames[variant]!;
    
    // Encode query to be safe for URL
    final encodedQuery = Uri.encodeComponent(query.trim());
    final uri = '$scheme://search?keyword=$encodedQuery';

    logger.i('[TikTokSeedingService] Opening Search on $serial: $uri');

    try {
      // 0. Force stop TikTok để reset session (tùy chọn nhưng khuyến nghị cho seeding sạch)
      await Process.run('adb', [
        '-s',
        serial,
        'shell',
        'am',
        'force-stop',
        packageName,
      ]);

      // 1. Mở Deep Link qua ADB
      final result = await Process.run('adb', [
        '-s',
        serial,
        'shell',
        'am',
        'start',
        '-a',
        'android.intent.action.VIEW',
        '-d',
        uri,
        packageName,
      ]);

      if (result.stdout.toString().contains('Error') || 
          result.stderr.toString().contains('Error')) {
        throw Exception(result.stderr.toString().isNotEmpty 
            ? result.stderr.toString() 
            : result.stdout.toString());
      }
      
      logger.i('[TikTokSeedingService] Mở Search thành công trên $serial');
    } catch (e) {
      logger.e('[TikTokSeedingService] Lỗi khi mở Search trên $serial', error: e);
      throw AkiRemoteException('Không thể mở tìm kiếm TikTok: $e');
    }
  }
}
