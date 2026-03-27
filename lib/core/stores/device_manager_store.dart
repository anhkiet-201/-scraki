import 'package:flutter/foundation.dart';
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
    await result.fold(
      (failure) async {
        runInAction(() {
          errorMessage = failure.message;
          logger.e('[DeviceManagerStore] Load devices failed: ${failure.message}');
        });
      },
      (newList) async {
        // Chuyển việc tính toán Diff sang Isolate để tránh block UI [Rule #10]
        final currentList = devices.toList();
        final diff = await compute<_DiffInput, _DiffResult>(
          _DeviceDiffHelper.calculateDiff,
          _DiffInput(currentList, newList),
        );

        runInAction(() {
          logger.i(
            '[DeviceManagerStore] Syncing ${newList.length} devices (Added: ${diff.toAdd.length}, Updated: ${diff.toUpdate.length}, Removed: ${diff.serialsToRemove.length})',
          );

          // 1. Loại bỏ các thiết bị không còn kết nối
          if (diff.serialsToRemove.isNotEmpty) {
            devices.removeWhere((d) => diff.serialsToRemove.contains(d.serial));
          }

          // 2. Map serial -> index hiện tại để update nhanh
          final Map<String, int> currentIndices = {
            for (int i = 0; i < devices.length; i++) devices[i].serial: i
          };

          // 3. Thực hiện update và add
          // Update các device đang tồn tại
          for (final update in diff.toUpdate) {
            final idx = currentIndices[update.serial];
            if (idx != null) {
              devices[idx] = update;
            }
          }

          // Thêm mới các device
          if (diff.toAdd.isNotEmpty) {
            devices.addAll(diff.toAdd);
          }
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

  @computed
  int get connectedBoxCount => devices
      .where(
        (d) => d.serial.startsWith('192.168.') && d.serial.endsWith('.20:5555'),
      )
      .length;

  /// Kết nối tới các Box trong dải IP 192.168.1.20 -> 192.168.96.20
  @action
  Future<void> connectToBox() async {
    errorMessage = null;

    // Wrap to show loading
    loadDevicesFuture = ObservableFuture(_connectToBoxInternal());
    await loadDevicesFuture;
  }

  Future<void> _connectToBoxInternal() async {
    // 1. Ensure we have the latest list
    logger.i(
      '[DeviceManagerStore] Refreshing device list before connecting...',
    );
    await _loadDevicesInternal();

    // 2. Build target IP list (1-96)
    final allIps = List.generate(96, (index) => '192.168.${index + 1}.20');

    // 3. Filter out already connected IPs
    final currentSerials = devices.map((d) => d.serial).toSet();
    final targets = allIps.where((ip) {
      return !currentSerials.contains('$ip:5555');
    }).toList();

    if (targets.isEmpty) {
      logger.i('[DeviceManagerStore] All devices already connected.');
      return;
    }

    logger.i(
      '[DeviceManagerStore] Connecting ${targets.length} devices in parallel...',
    );

    // 4. Connect ALL targets in parallel, each with an individual timeout.
    // Failures/timeouts are caught per-IP and do not block the others.
    const connectTimeout = Duration(seconds: 3);
    await Future.wait(
      targets.map((ip) async {
        try {
          await _repository.connectTcp(ip, 5555).timeout(connectTimeout);
        } catch (_) {
          // Ignore individual failures (timeout, unreachable host, etc.)
        }
      }),
    );

    // 5. Final Reload
    await _loadDevicesInternal();
    logger.i('[DeviceManagerStore] Done. $connectedBoxCount boxes connected.');
  }
}

class _DiffInput {
  final List<DeviceEntity> currentList;
  final List<DeviceEntity> newList;
  _DiffInput(this.currentList, this.newList);
}

class _DiffResult {
  final List<DeviceEntity> toAdd;
  final List<DeviceEntity> toUpdate;
  final Set<String> serialsToRemove;
  _DiffResult(this.toAdd, this.toUpdate, this.serialsToRemove);
}

class _DeviceDiffHelper {
  static _DiffResult calculateDiff(_DiffInput input) {
    final currentMap = {for (final d in input.currentList) d.serial: d};
    final newSerials = input.newList.map((d) => d.serial).toSet();

    final toAdd = <DeviceEntity>[];
    final toUpdate = <DeviceEntity>[];
    final serialsToRemove = <String>{};

    // Tìm device mới hoặc cần update
    for (final newDevice in input.newList) {
      final existing = currentMap[newDevice.serial];
      if (existing != null) {
        if (existing != newDevice) {
          toUpdate.add(newDevice);
        }
      } else {
        toAdd.add(newDevice);
      }
    }

    // Tìm device đã mất kết nối
    for (final oldDevice in input.currentList) {
      if (!newSerials.contains(oldDevice.serial)) {
        serialsToRemove.add(oldDevice.serial);
      }
    }

    return _DiffResult(toAdd, toUpdate, serialsToRemove);
  }
}
