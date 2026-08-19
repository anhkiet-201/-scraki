import 'package:injectable/injectable.dart';
import 'package:scrcpy_flutter_plugin/scrcpy_flutter_plugin.dart';
import 'package:scraki/core/utils/logger.dart';

/// Quản lý pool [ScrcpyController] theo [sessionId].
///
/// Mỗi [sessionId] (ví dụ: "serial_grid" hoặc "serial_floating") sẽ có một controller riêng biệt.
/// 1 sessionId = 1 controller = 1 tiến trình scrcpy.
@lazySingleton
class ScrcpyControllerService {
  final Map<String, ScrcpyController> _controllers = {};
  final Map<String, int> _sessionPorts = {};
  int _nextPort = 20000 + DateTime.now().millisecondsSinceEpoch % 20000;

  /// Cấp phát một port riêng biệt cho mỗi sessionId để tránh xung đột 'Address already in use'
  int getPortForSession(String sessionId) {
    if (!_sessionPorts.containsKey(sessionId)) {
      _sessionPorts[sessionId] = _nextPort;
      _nextPort += 20; // Dành một khoảng 20 port cho mỗi session để scrcpy tự động retry
      if (_nextPort > 45000) {
        _nextPort = 20000 + DateTime.now().millisecondsSinceEpoch % 20000; 
      }
    }
    return _sessionPorts[sessionId]!;
  }

  /// Lấy controller hiện tại cho [sessionId], hoặc tạo mới nếu chưa có.
  ScrcpyController getOrCreate(String sessionId) {
    if (_controllers.containsKey(sessionId)) {
      logger.d('[ScrcpyControllerService] Reusing controller for $sessionId');
      return _controllers[sessionId]!;
    }
    logger.d('[ScrcpyControllerService] Creating new controller for $sessionId');
    final controller = ScrcpyController();
    _controllers[sessionId] = controller;
    return controller;
  }

  /// Lấy controller hiện tại cho [sessionId] nếu tồn tại, null nếu không có.
  ScrcpyController? get(String sessionId) => _controllers[sessionId];

  /// Dừng và giải phóng controller cho [sessionId].
  void release(String sessionId) {
    final controller = _controllers.remove(sessionId);
    if (controller != null) {
      logger.i('[ScrcpyControllerService] Disposing controller for $sessionId');
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
    _sessionPorts.clear();
    _nextPort = 27183;
    ScrcpyController.cleanupAll();
  }
}
