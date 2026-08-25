import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/domain/entities/mirror_session.dart';
import 'package:scraki/features/device/domain/services/device_shell.dart';

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

  @observable
  ObservableMap<String, double> deviceAspectRatios =
      ObservableMap<String, double>();

  Map<String, DeviceShell> get activeDeviceShells {
    return activeSessions.map((k,v) => MapEntry(k.replaceAll("_grid", "").replaceAll("_floating", ""),v.deviceShell));
  }


  @action
  void updateDeviceAspectRatio(String serial, double ratio) {
    if (deviceAspectRatios[serial] != ratio) {
      deviceAspectRatios[serial] = ratio;
    }
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
    String? status,
    String? label,
    DeviceTaskPhase phase = DeviceTaskPhase.running,
    bool isRunning = true,
  }) {
    logger.i('[SessionManagerStore] updateDeviceTask: $serial, type: $type, phase: $phase');
    if (!isRunning) {
      activeTasks.remove(serial);
      return;
    }

    final currentTask = activeTasks[serial];
    if (currentTask != null && currentTask.type == type) {
      activeTasks[serial] = currentTask.copyWith(status: status, phase: phase);
    } else {
      activeTasks[serial] = DeviceTaskState(
        type: type,
        status: status ?? '',
        taskLabel: label,
        phase: phase,
      );
    }
  }

  @action
  void clearDeviceTask(String serial) {
    logger.i('[SessionManagerStore] clearDeviceTask: $serial');
    activeTasks.remove(serial);
  }
}

enum DeviceTaskType { push, install, videoGen, imagePost, script, command, facebookVideo, facebookImage }

enum DeviceTaskPhase { running, success, failed }

class DeviceTaskState {
  final DeviceTaskType type;
  final String status;
  final String? taskLabel;
  final DeviceTaskPhase phase;

  DeviceTaskState({
    required this.type,
    this.taskLabel,
    this.status = '',
    this.phase = DeviceTaskPhase.running,
  });

  DeviceTaskState copyWith({
    String? status,
    DeviceTaskPhase? phase,
  }) {
    return DeviceTaskState(
      type: type,
      taskLabel: taskLabel,
      status: status ?? this.status,
      phase: phase ?? this.phase,
    );
  }

  bool get autoMinimize =>
      type == DeviceTaskType.script ||
      type == DeviceTaskType.command ||
      type == DeviceTaskType.push ||
      type == DeviceTaskType.install;

  String get label {
    if(taskLabel != null) return taskLabel!;
    switch (type) {
      case DeviceTaskType.push:
        return 'Đẩy file';
      case DeviceTaskType.install:
        return 'Cài đặt APK';
      case DeviceTaskType.videoGen:
        return 'TikTok Video';
      case DeviceTaskType.imagePost:
        return 'TikTok Bộ ảnh';
      case DeviceTaskType.facebookVideo:
        return 'Facebook Video';
      case DeviceTaskType.facebookImage:
        return 'Facebook Bộ ảnh';
      case DeviceTaskType.script:
        return 'Thực thi Script';
      case DeviceTaskType.command:
        return 'Thực thi Lệnh';
    }
  }
}
