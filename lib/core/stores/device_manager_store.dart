import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/data/services/scrcpy_controller_service.dart';
import 'package:scraki/features/device/domain/entities/device_entity.dart';
import 'package:scraki/features/device/domain/repositories/device_repository.dart';
import '../config/settings_config_provider.dart';

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
  final SettingsConfigProvider _configProvider;

  _DeviceManagerStore(this._repository, this._configProvider);

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

    // 1. Lập tức giải phóng controller scrcpy và session của thiết bị
    try {
      final controllerService = getIt<ScrcpyControllerService>();
      final sessionManagerStore = getIt<SessionManagerStore>();
      controllerService.release('${serial}_grid');
      controllerService.release('${serial}_floating');
      controllerService.release(serial);
      sessionManagerStore.activeSessions.remove('${serial}_grid');
      sessionManagerStore.activeSessions.remove('${serial}_floating');
      sessionManagerStore.activeSessions.remove(serial);
      if (sessionManagerStore.floatingSerial == serial) {
        sessionManagerStore.floatingSerial = null;
      }
    } catch (e) {
      logger.w('[DeviceManagerStore] Failed to cleanup session during disconnect: $e');
    }

    // 2. Lập tức xóa khỏi danh sách local để UI cập nhật ngay mà không bị block
    runInAction(() {
      devices.removeWhere((d) => d.serial == serial);
      selectedSerials.remove(serial);
    });

    // 3. Thực hiện ngắt kết nối ADB bất đồng bộ với timeout
    try {
      final result = await _repository
          .disconnectDevice(serial)
          .timeout(const Duration(seconds: 3));
      result.fold(
        (failure) {
          logger.w(
            '[DeviceManagerStore] ADB disconnect returned warning/error: ${failure.message}',
          );
        },
        (_) {
          logger.i('[DeviceManagerStore] ADB disconnect completed for $serial');
        },
      );
    } catch (e) {
      logger.w('[DeviceManagerStore] ADB disconnect timed out or failed: $e');
    }
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
  int get connectedBoxCount {
    final ipPrefix = _configProvider.ipRange.split('.').take(2).join('.');
    final targetPrefix = ipPrefix.isNotEmpty ? ipPrefix : '10.10';
    return devices
        .where(
          (d) => d.serial.startsWith('$targetPrefix.') && d.serial.endsWith('.20:5555'),
        )
        .length;
  }

  /// Kết nối tới các Box trong dải IP từ cấu hình (ví dụ: 10.10.1.20 -> 10.10.N.20)
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

    // 2. Build target IP list (1-N)
    final ipPrefix = _configProvider.ipRange.split('.').take(2).join('.');
    final targetPrefix = ipPrefix.isNotEmpty ? ipPrefix : '10.10';
    final allIps = List.generate(_configProvider.maxDevices, (index) => '$targetPrefix.${index + 1}.20');

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
