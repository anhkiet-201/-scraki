import 'package:injectable/injectable.dart';
import 'package:scrcpy_flutter_plugin/scrcpy_flutter_plugin.dart';
import 'package:scraki/core/utils/logger.dart';

/// Quản lý pool [ScrcpyController] theo [serial] thiết bị.
///
/// Hỗ trợ reuse controller khi cùng serial xuất hiện ở cả Grid và Floating view,
/// và giải phóng tài nguyên native khi không còn consumer nào dùng session.
@lazySingleton
class ScrcpyControllerService {
  final Map<String, ScrcpyController> _controllers = {};

  /// Lấy controller hiện tại cho [serial], hoặc tạo mới nếu chưa có.
  ScrcpyController getOrCreate(String serial) {
    if (_controllers.containsKey(serial)) {
      logger.d('[ScrcpyControllerService] Reusing controller for $serial');
      return _controllers[serial]!;
    }
    logger.d('[ScrcpyControllerService] Creating new controller for $serial');
    final controller = ScrcpyController();
    _controllers[serial] = controller;
    return controller;
  }

  /// Lấy controller hiện tại cho [serial] nếu tồn tại, null nếu không có.
  ScrcpyController? get(String serial) => _controllers[serial];

  /// Dừng và giải phóng controller của [serial].
  void dispose(String serial) {
    final controller = _controllers.remove(serial);
    if (controller != null) {
      logger.i('[ScrcpyControllerService] Disposing controller for $serial');
      controller.stop();
      controller.dispose();
    }
  }

  /// Dừng và giải phóng tất cả controller (dùng khi app thoát hoặc hot restart).
  void disposeAll() {
    logger.i('[ScrcpyControllerService] Disposing all ${_controllers.length} controllers');
    for (final entry in _controllers.entries) {
      entry.value.stop();
      entry.value.dispose();
    }
    _controllers.clear();
    ScrcpyController.cleanupAll();
  }
}
