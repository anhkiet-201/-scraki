import 'package:mobx/mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/data/datasources/adb_remote_data_source.dart';

part 'floating_tool_box_store.g.dart';

// ignore: library_private_types_in_public_api
class FloatingToolBoxStore = _FloatingToolBoxStore with _$FloatingToolBoxStore;

/// Store quản lý state cho Floating Tool Box
///
/// Simplified version - chỉ quản lý Power button
abstract class _FloatingToolBoxStore with Store {
  final IAdbRemoteDataSource _adbDataSource;

  _FloatingToolBoxStore() : _adbDataSource = getIt<IAdbRemoteDataSource>();

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
