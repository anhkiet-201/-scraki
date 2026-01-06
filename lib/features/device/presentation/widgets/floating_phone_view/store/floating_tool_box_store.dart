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

  /// Bật/tắt hiển thị menu chọn việc làm.
  @action
  void toggleJobSelector() {
    showJobSelector = !showJobSelector;
  }

  /// Ẩn menu chọn việc làm.
  @action
  void hideJobSelector() {
    showJobSelector = false;
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
}
