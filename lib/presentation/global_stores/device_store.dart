import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/device_entity.dart';
import '../../../domain/repositories/device_repository.dart';

part 'device_store.g.dart';

@lazySingleton
// ignore: library_private_types_in_public_api
class DeviceStore = _DeviceStore with _$DeviceStore;

/// Store responsible for managing device discovery and connections.
///
/// Handles:
/// - Device list management
/// - ADB device discovery
/// - TCP/IP connections
/// - Device disconnection
abstract class _DeviceStore with Store {
  final DeviceRepository _repository;

  _DeviceStore(this._repository);

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

  @action
  Future<void> connectTcp(String ip, int port) async {
    errorMessage = null;
    logger.i('[DeviceStore] Connecting to TCP device: $ip:$port');

    final result = await _repository.connectTcp(ip, port);
    await result.fold(
      (failure) async {
        logger.e('[DeviceStore] TCP connection failed', error: failure.message);
        runInAction(() => errorMessage = failure.message);
      },
      (_) async {
        logger.i('[DeviceStore] TCP connection successful');
        await loadDevices();
      },
    );
  }

  @action
  Future<void> disconnect(String serial) async {
    errorMessage = null;
    logger.i('[DeviceStore] Disconnecting device: $serial');

    final result = await _repository.disconnectDevice(serial);
    await result.fold(
      (failure) async {
        logger.e('[DeviceStore] Disconnection failed', error: failure.message);
        runInAction(() => errorMessage = failure.message);
      },
      (_) async {
        logger.i('[DeviceStore] Device disconnected successfully');
        await loadDevices();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DEVICE SELECTION
  // ═══════════════════════════════════════════════════════════════

  @action
  void toggleDeviceSelection(String serial) {
    if (selectedSerials.contains(serial)) {
      selectedSerials.remove(serial);
    } else {
      selectedSerials.add(serial);
    }
  }

  @action
  void toggleBroadcasting() {
    isBroadcastingMode = !isBroadcastingMode;
  }

  @action
  void clearSelection() {
    selectedSerials.clear();
  }
}
