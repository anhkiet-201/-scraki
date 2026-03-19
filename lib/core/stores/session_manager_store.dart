import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/constants/ui_constants.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/domain/entities/mirror_session.dart';

part 'session_manager_store.g.dart';

@lazySingleton
// ignore: library_private_types_in_public_api
class SessionManagerStore = _SessionManagerStore with _$SessionManagerStore;

/// Store chịu trách nhiệm quản lý các phiên phản chiếu (mirroring sessions) và xử lý đầu vào.
///
/// Chức năng chính:
/// - Quản lý vòng đời Mirroring (start/stop)
/// - Quản lý danh sách các session đang hoạt động
/// - Xử lý sự kiện đầu vào (touch, keyboard, scroll)
/// - Xử lý kéo thả file (drag & drop)
/// - Đồng bộ Clipboard
/// - Phát hiện thao tác double-tap để mở cửa sổ nổi
abstract class _SessionManagerStore with Store {
  _SessionManagerStore();

  // ═══════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  @observable
  ObservableMap<String, MirrorSession> activeSessions =
      ObservableMap<String, MirrorSession>();

  @computed
  double get deviceAspectRatio {
    const double defaultVideoRatio = 9 / 19; // Modern phone ratio
    final double fallbackRatio = defaultVideoRatio;

    if (activeSessions.isEmpty) return fallbackRatio;

    // Sử dụng tỷ lệ khung hình của session hoạt động đầu tiên cho toàn bộ lưới
    // Logic: Tỷ lệ = Chiều rộng / (Chiều cao + Chiều cao thanh điều hướng)
    final firstSession = activeSessions.values.first;
    if (firstSession.width > 0 && firstSession.height > 0) {
      return firstSession.width /
          (firstSession.height + UIConstants.gridNavigationBarHeight);
    }
    return fallbackRatio;
  }

  // ═══════════════════════════════════════════════════════════════
  // FLOATING WINDOW
  // ═══════════════════════════════════════════════════════════════

  @observable
  String? floatingSerial;

  @computed
  bool get isFloatingVisible => floatingSerial != null;

  @action
  void toggleFloating(String? serial) {
    if (floatingSerial == serial) {
      floatingSerial = null;
    } else {
      floatingSerial = serial;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DEVICE TASKS (PERSISTENT OVERLAYS)
  // ═══════════════════════════════════════════════════════════════
  
  @observable
  ObservableMap<String, DeviceTaskState?> activeTasks = 
      ObservableMap<String, DeviceTaskState?>();

  @action
  void updateDeviceTask(
    String serial, {
    required DeviceTaskType type,
    double? progress,
    String? status,
    bool isRunning = true,
  }) {
    logger.i('[SessionManagerStore] updateDeviceTask: $serial, type: $type, running: $isRunning, progress: $progress');
    if (!isRunning) {
      activeTasks.remove(serial);
      return;
    }

    final currentTask = activeTasks[serial];
    if (currentTask != null && currentTask.type == type) {
      activeTasks[serial] = currentTask.copyWith(
        progress: progress,
        status: status,
      );
    } else {
      activeTasks[serial] = DeviceTaskState(
        type: type,
        progress: progress ?? 0.0,
        status: status ?? '',
      );
    }
  }

  @action
  void clearDeviceTask(String serial) {
    logger.i('[SessionManagerStore] clearDeviceTask: $serial');
    activeTasks.remove(serial);
  }
}

enum DeviceTaskType { push, install, videoGen }

class DeviceTaskState {
  final DeviceTaskType type;
  final double progress;
  final String status;

  DeviceTaskState({
    required this.type,
    this.progress = 0.0,
    this.status = '',
  });

  DeviceTaskState copyWith({
    double? progress,
    String? status,
  }) {
    return DeviceTaskState(
      type: type,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }

  String get label {
    switch (type) {
      case DeviceTaskType.push:
        return 'Pushing files...';
      case DeviceTaskType.install:
        return 'Installing APK...';
      case DeviceTaskType.videoGen:
        return 'Generating Video...';
    }
  }
}
