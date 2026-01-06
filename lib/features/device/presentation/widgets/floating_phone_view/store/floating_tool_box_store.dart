import 'package:mobx/mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/device/data/datasources/adb_remote_data_source.dart';

part 'floating_tool_box_store.g.dart';

// ignore: library_private_types_in_public_api
class FloatingToolBoxStore = _FloatingToolBoxStore with _$FloatingToolBoxStore;

/// Store quản lý state cho Floating Tool Box
abstract class _FloatingToolBoxStore with Store {
  final IAdbRemoteDataSource _adbDataSource;

  _FloatingToolBoxStore() : _adbDataSource = getIt<IAdbRemoteDataSource>();

  /// UI State: Show/hide job selector
  @observable
  bool showJobSelector = false;

  /// Toggle job selector visibility
  @action
  void toggleJobSelector() {
    showJobSelector = !showJobSelector;
  }

  /// Hide job selector
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
