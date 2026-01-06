import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/domain/repositories/device_repository.dart';

part 'device_manager_store.g.dart';

@lazySingleton
// ignore: library_private_types_in_public_api
class DeviceManagerStore = _DeviceManagerStore with _$DeviceManagerStore;

/// Store chịu trách nhiệm quản lý việc tìm kiếm và kết nối thiết bị.
///
/// Chức năng chính:
/// - Quản lý danh sách thiết bị
/// - Tìm kiếm thiết bị qua ADB
/// - Kết nối TCP/IP
/// - Ngắt kết nối thiết bị
abstract class _DeviceManagerStore with Store {
  final DeviceRepository _repository;

  _DeviceManagerStore(this._repository);

  // ═══════════════════════════════════════════════════════════════
  // DEVICE LIST
  // ═══════════════════════════════════════════════════════════════

  @observable
  ObservableList<DeviceEntity> devices = ObservableList<DeviceEntity>();

  @observable
  ObservableSet<String> selectedSerials = ObservableSet<String>();

  @observable
  bool isBroadcastingMode = false;

  // ═══════════════════════════════════════════════════════════════
  // LOADING STATE
  // ═══════════════════════════════════════════════════════════════

  @observable
  ObservableFuture<void>? loadDevicesFuture;

  @observable
  String? errorMessage;

  @computed
  bool get isLoading => loadDevicesFuture?.status == FutureStatus.pending;

  // ═══════════════════════════════════════════════════════════════
  // DEVICE ACTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Tải danh sách thiết bị từ ADB.
  @action
  Future<void> loadDevices() async {
    errorMessage = null;
    loadDevicesFuture = ObservableFuture(_loadDevicesInternal());
    await loadDevicesFuture;
  }

  Future<void> _loadDevicesInternal() async {
    final result = await _repository.getConnectedDevices();
    result.fold(
      (failure) {
        runInAction(() {
          errorMessage = failure.message;
          devices.clear();
        });
      },
      (list) {
        runInAction(() {
          devices.clear();
          devices.addAll(list);
        });
      },
    );
  }

  /// Kết nối tới thiết bị qua địa chỉ IP và Port (TCP/IP).
  @action
  Future<void> connectTcp(String ip, int port) async {
    errorMessage = null;
    logger.i('[DeviceManagerStore] Connecting to TCP device: $ip:$port');

    final result = await _repository.connectTcp(ip, port);
    await result.fold(
      (failure) async {
        logger.e(
          '[DeviceManagerStore] TCP connection failed',
          error: failure.message,
        );
        runInAction(() => errorMessage = failure.message);
      },
      (_) async {
        logger.i('[DeviceManagerStore] TCP connection successful');
        await loadDevices();
      },
    );
  }

  /// Ngắt kết nối thiết bị.
  @action
  Future<void> disconnect(String serial) async {
    errorMessage = null;
    logger.i('[DeviceManagerStore] Disconnecting device: $serial');

    final result = await _repository.disconnectDevice(serial);
    await result.fold(
      (failure) async {
        logger.e(
          '[DeviceManagerStore] Disconnection failed',
          error: failure.message,
        );
        runInAction(() => errorMessage = failure.message);
      },
      (_) async {
        logger.i('[DeviceManagerStore] Device disconnected successfully');
        await loadDevices();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DEVICE SELECTION
  // ═══════════════════════════════════════════════════════════════

  /// Chọn hoặc bỏ chọn thiết bị để thực hiện thao tác hàng loạt.
  @action
  void toggleDeviceSelection(String serial) {
    if (selectedSerials.contains(serial)) {
      selectedSerials.remove(serial);
    } else {
      selectedSerials.add(serial);
    }
  }

  /// Bật/Tắt chế độ điều khiển đồng loạt (Broadcasting).
  /// Khi bật, thao tác trên một thiết bị sẽ được gửi tới tất cả các thiết bị đang chọn.
  @action
  void toggleBroadcasting() {
    isBroadcastingMode = !isBroadcastingMode;
  }

  /// Xóa toàn bộ danh sách thiết bị đã chọn.
  @action
  void clearSelection() {
    selectedSerials.clear();
  }
}
