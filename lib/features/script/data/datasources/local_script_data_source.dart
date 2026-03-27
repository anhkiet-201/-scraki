import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import '../models/script_model.dart';
import '../../domain/entities/script_entity.dart';

abstract class LocalScriptDataSource {
  Future<List<ScriptEntity>> getAllScripts();
  Future<void> saveScript(ScriptEntity script);
  Future<void> deleteScript(String id);
  Future<void> initDefaultScripts();
}

@Named('local_script')
@LazySingleton(as: LocalScriptDataSource)
class LocalScriptDataSourceImpl implements LocalScriptDataSource {
  static const String _boxName = 'scripts_box';

  Future<Box<ScriptModel>> get _box async => await Hive.openBox<ScriptModel>(_boxName);

  @override
  Future<List<ScriptEntity>> getAllScripts() async {
    final box = await _box;
    if (box.isEmpty) {
      await initDefaultScripts();
    }
    return box.values.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> saveScript(ScriptEntity script) async {
    final box = await _box;
    await box.put(script.id, ScriptModel.fromEntity(script));
  }

  @override
  Future<void> deleteScript(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  @override
  Future<void> initDefaultScripts() async {
    final box = await _box;
    if (box.isNotEmpty) return;

    final defaultScripts = [
      ScriptEntity(
        id: '1',
        name: 'Dọn dẹp Cache TikTok',
        description: 'Xóa cache của ứng dụng TikTok để giải phóng bộ nhớ.',
        commands: [
          'pm clear com.zhiliaoapp.musically',
          'pm clear com.ss.android.ugc.trill',
        ],
        tags: ['Cleanup', 'TikTok'],
      ),
      ScriptEntity(
        id: '2',
        name: 'Lấy thông tin hệ thống',
        description: 'Xem thông tin về phiên bản Android và bộ nhớ.',
        commands: [
          'getprop ro.build.version.release',
          'df -h /data',
        ],
        tags: ['System', 'Info'],
      ),
      ScriptEntity(
        id: '3',
        name: 'Chụp màn hình (Lưu vào /sdcard)',
        description: 'Chụp ảnh màn hình và lưu vào bộ nhớ máy.',
        commands: [
          'screencap -p /sdcard/screenshot.png',
        ],
        tags: ['Media'],
      ),
      ScriptEntity(
        id: '4',
        name: 'Mở Cài đặt Wi-Fi',
        description: 'Mở thẳng trang cài đặt Wi-Fi trên thiết bị.',
        commands: [
          'am start -a android.settings.WIFI_SETTINGS',
        ],
        tags: ['Settings'],
      ),
    ];

    for (final script in defaultScripts) {
      await box.put(script.id, ScriptModel.fromEntity(script));
    }
  }
}
