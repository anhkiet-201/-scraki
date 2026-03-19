import 'package:mobx/mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/device/data/datasources/adb_remote_data_source.dart';

part 'floating_tool_box_store.g.dart';

// ignore: library_private_types_in_public_api
class FloatingToolBoxStore = _FloatingToolBoxStore with _$FloatingToolBoxStore;

/// Store quản lý state cho Floating Tool Box.
///
/// Chức năng chính:
/// - Quản lý hiển thị menu chọn việc làm (Job Selector)
/// - Gửi lệnh phím nguồn
abstract class _FloatingToolBoxStore with Store {
  final IAdbRemoteDataSource _adbDataSource;

  _FloatingToolBoxStore() : _adbDataSource = getIt<IAdbRemoteDataSource>();

  /// UI State: Hiển thị/ẩn menu chọn việc làm
  @observable
  bool showJobSelector = false;

  /// UI State: Hiển thị/ẩn panel đọc email
  @observable
  bool showEmailPanel = false;

  /// UI State: Hiển thị/ẩn panel Authenticator
  @observable
  bool showAuthPanel = false;

  /// Bật/tắt hiển thị menu chọn việc làm.
  @action
  void toggleJobSelector() {
    showEmailPanel = false;
    showJobSelector = !showJobSelector;
  }

  /// Ẩn menu chọn việc làm.
  @action
  void hideJobSelector() {
    showJobSelector = false;
  }

  /// Bật/tắt hiển thị email panel.
  @action
  void toggleEmailPanel() {
    showJobSelector = false;
    showEmailPanel = !showEmailPanel;
  }

  /// Ẩn email panel.
  @action
  void hideEmailPanel() {
    showEmailPanel = false;
  }

  /// Bật/tắt hiển thị Authenticator panel.
  @action
  void toggleAuthPanel() {
    showJobSelector = false;
    showEmailPanel = false;
    showAuthPanel = !showAuthPanel;
  }

  /// Ẩn Authenticator panel.
  @action
  void hideAuthPanel() {
    showAuthPanel = false;
  }

  /// Gửi POWER key để bật/tắt màn hình
  @action
  Future<void> sendPowerButton(String serial) async {
    try {
      await _adbDataSource.sendPowerKey(serial);
    } catch (e) {
      // Log error hoặc show snackbar
      // Tạm thời ignore error
    }
  }

  /// Mở trang Inbox TikTok qua ADB intent (Global / Asia / Lite).
  @action
  Future<void> openTikTokInbox(String serial) async {
    try {
      await _adbDataSource.openTikTokInbox(serial);
    } catch (_) {
      // Ignore nếu TikTok chưa cài
    }
  }

  /// Mở trang Profile TikTok qua ADB intent (Global / Asia / Lite).
  @action
  Future<void> openTikTokProfile(String serial) async {
    try {
      await _adbDataSource.openTikTokProfile(serial);
    } catch (_) {
      // Ignore nếu TikTok chưa cài
    }
  }
}
