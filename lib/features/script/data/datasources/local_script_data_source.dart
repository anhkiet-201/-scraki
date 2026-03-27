import 'package:injectable/injectable.dart';
import '../../domain/entities/script_entity.dart';

abstract class LocalScriptDataSource {
  Future<List<ScriptEntity>> getPredefinedScripts();
}

@Named('local_script')
@LazySingleton(as: LocalScriptDataSource)
class LocalScriptDataSourceImpl implements LocalScriptDataSource {
  @override
  Future<List<ScriptEntity>> getPredefinedScripts() async {
    return [
      ScriptEntity(
        id: '1',
        name: 'Dọn dẹp Cache TikTok',
        description: 'Xóa cache của ứng dụng TikTok để giải phóng bộ nhớ.',
        commands: [
          'pm clear com.zhiliaoapp.musically',
          'pm clear com.ss.android.ugc.trill',
        ],
      ),
      ScriptEntity(
        id: '2',
        name: 'Lấy thông tin hệ thống',
        description: 'Xem thông tin về phiên bản Android và bộ nhớ.',
        commands: [
          'getprop ro.build.version.release',
          'df -h /data',
        ],
      ),
      ScriptEntity(
        id: '3',
        name: 'Chụp màn hình (Lưu vào /sdcard)',
        description: 'Chụp ảnh màn hình và lưu vào bộ nhớ máy.',
        commands: [
          'screencap -p /sdcard/screenshot.png',
        ],
      ),
      ScriptEntity(
        id: '4',
        name: 'Mở Cài đặt Wi-Fi',
        description: 'Mở thẳng trang cài đặt Wi-Fi trên thiết bị.',
        commands: [
          'am start -a android.settings.WIFI_SETTINGS',
        ],
      ),
    ];
  }
}
