import 'package:injectable/injectable.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/data/datasources/adb_remote_data_source.dart';
import 'package:scraki/features/device/data/datasources/scrcpy_service.dart';
import 'package:scraki/features/device/domain/services/i_device_task_service.dart';
import 'package:scraki/features/device/domain/services/i_tiktok_post_service.dart';
import 'package:scraki/features/device/domain/services/i_facebook_post_service.dart';
import 'package:scraki/features/device/data/services/file_upload_task_classifier.dart';

@LazySingleton(as: IDeviceTaskService)
class DeviceTaskServiceImpl implements IDeviceTaskService {
  final SessionManagerStore _sessionManagerStore;
  final ITikTokPostService _tikTokService;
  final IFacebookPostService _facebookService;
  final IAdbRemoteDataSource _adbDataSource;
  final ScrcpyService _scrcpyService;

  DeviceTaskServiceImpl(
    this._sessionManagerStore,
    this._tikTokService,
    this._facebookService,
    this._adbDataSource,
    this._scrcpyService,
  );

  bool _isCanceled(String serial) {
    return _sessionManagerStore.activeTasks[serial]?.status == 'Đã hủy!';
  }

  @override
  void cancelTask(String serial) {
    final task = _sessionManagerStore.activeTasks[serial];
    if (task != null) {
      if (task.type != DeviceTaskType.script &&
          task.type != DeviceTaskType.command) {
        _sessionManagerStore.updateDeviceTask(
          serial,
          type: task.type,
          status: 'Đã hủy!',
          phase: DeviceTaskPhase.failed,
        );
        Future.delayed(const Duration(seconds: 2), () {
          final currentTask = _sessionManagerStore.activeTasks[serial];
          if (currentTask != null &&
              currentTask.phase == DeviceTaskPhase.failed &&
              currentTask.status == 'Đã hủy!') {
            _sessionManagerStore.clearDeviceTask(serial);
          }
        });
      }
    } else {
      _sessionManagerStore.clearDeviceTask(serial);
    }
  }

  @override
  Future<void> executeFileUploadTask(String serial, List<String> paths) async {
    final classifier = FileUploadTaskClassifier(paths);
    if (classifier.isEmpty) return;

    final taskType = classifier.determineTaskType();
    final fileName = classifier.fileName;
    final isXapk = classifier.isXapk;
    final isSetDir = classifier.isSetDir;
    final isVideo = classifier.isVideo;

    try {
      await _dispatchTask(
        serial: serial,
        paths: paths,
        taskType: taskType,
        fileName: fileName,
        isSetDir: isSetDir,
        isVideo: isVideo,
        isXapk: isXapk,
      );
    } catch (e) {
      logger.e('[DeviceTaskService] Task failed', error: e);
      if (_isCanceled(serial)) return;
      _sessionManagerStore.updateDeviceTask(
        serial,
        type: taskType,
        status: 'Lỗi: $e',
        phase: DeviceTaskPhase.failed,
      );
      await Future<void>.delayed(const Duration(seconds: 3));
    } finally {
      if (!_isCanceled(serial)) {
        _sessionManagerStore.clearDeviceTask(serial);
      }
    }
  }

  Future<void> _dispatchTask({
    required String serial,
    required List<String> paths,
    required DeviceTaskType taskType,
    required String fileName,
    required bool isSetDir,
    required bool isVideo,
    required bool isXapk,
  }) async {
    switch (taskType) {
      case DeviceTaskType.facebookImage:
        if (isSetDir) {
          await _handleFacebookImage(serial, paths.first, fileName);
        } else {
          await _handleFacebookSingleFile(
            serial,
            paths,
            fileName,
            DeviceTaskType.facebookImage,
          );
        }
        break;
      case DeviceTaskType.imagePost:
        await _handleSetDir(serial, paths.first, fileName);
        break;
      case DeviceTaskType.facebookVideo:
        await _handleFacebookSingleFile(
          serial,
          paths,
          fileName,
          DeviceTaskType.facebookVideo,
        );
        break;
      case DeviceTaskType.videoGen:
      case DeviceTaskType.push:
        if (isVideo) {
          await _handleVideo(serial, paths, fileName);
        } else {
          await _handleDefaultPush(serial, paths);
        }
        break;
      case DeviceTaskType.install:
        await _handleInstall(serial, paths.first, fileName, isXapk: isXapk);
        break;
      default:
        await _handleDefaultPush(serial, paths);
    }
  }

  Future<void> _handleSetDir(
    String serial,
    String path,
    String fileName,
  ) async {
    _sessionManagerStore.updateDeviceTask(
      serial,
      type: DeviceTaskType.imagePost,
      status: 'Đang đẩy bộ ảnh $fileName...',
    );
    await _tikTokService.openTikTokPostImages(serial, path);
    if (_isCanceled(serial)) return;
    _sessionManagerStore.updateDeviceTask(
      serial,
      type: DeviceTaskType.imagePost,
      status: 'Sẵn sàng!',
      phase: DeviceTaskPhase.success,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  Future<void> _handleFacebookImage(
    String serial,
    String path,
    String fileName,
  ) async {
    _sessionManagerStore.updateDeviceTask(
      serial,
      type: DeviceTaskType.facebookImage,
      status: 'Đang đẩy bộ ảnh Facebook $fileName...',
    );
    final nameLower = fileName.toLowerCase();
    final FacebookPostTarget target;
    if (nameLower.contains('_groups_')) {
      target = FacebookPostTarget.group;
    } else if (nameLower.contains('_reels_')) {
      target = FacebookPostTarget.reels;
    } else {
      target = FacebookPostTarget.feed;
    }

    await _facebookService.openFacebookPostImages(serial, path, target: target);
    if (_isCanceled(serial)) return;
    _sessionManagerStore.updateDeviceTask(
      serial,
      type: DeviceTaskType.facebookImage,
      status: 'Sẵn sàng!',
      phase: DeviceTaskPhase.success,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  Future<void> _handleVideo(
    String serial,
    List<String> paths,
    String fileName,
  ) async {
    final isTikTokFinal = fileName.startsWith('tik_final_');
    final taskType = isTikTokFinal
        ? DeviceTaskType.videoGen
        : DeviceTaskType.push;
    final startStatus = 'Đang đẩy $fileName...';
    final successStatus = isTikTokFinal ? 'Sẵn sàng!' : 'Đã gửi thành công!';

    _sessionManagerStore.updateDeviceTask(
      serial,
      type: taskType,
      status: startStatus,
    );

    if (isTikTokFinal) {
      await _tikTokService.openTikTokCreate(serial, paths.first);
    } else {
      await _scrcpyService.pushFiles(serial, paths);
    }

    if (_isCanceled(serial)) return;

    _sessionManagerStore.updateDeviceTask(
      serial,
      type: taskType,
      status: successStatus,
      phase: DeviceTaskPhase.success,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  Future<void> _handleFacebookSingleFile(
    String serial,
    List<String> paths,
    String fileName,
    DeviceTaskType taskType,
  ) async {
    _sessionManagerStore.updateDeviceTask(
      serial,
      type: taskType,
      status: taskType == DeviceTaskType.facebookVideo
          ? 'Đang đẩy video Facebook $fileName...'
          : 'Đang đẩy ảnh Facebook $fileName...',
    );

    final FacebookPostTarget target;
    if (fileName.startsWith('fb_groups_')) {
      target = FacebookPostTarget.group;
    } else if (fileName.startsWith('fb_reels_')) {
      target = FacebookPostTarget.reels;
    } else {
      target = FacebookPostTarget.feed;
    }

    await _facebookService.openFacebookCreate(
      serial,
      paths.first,
      target: target,
    );
    if (_isCanceled(serial)) return;
    _sessionManagerStore.updateDeviceTask(
      serial,
      type: taskType,
      status: 'Sẵn sàng!',
      phase: DeviceTaskPhase.success,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  Future<void> _handleInstall(
    String serial,
    String path,
    String fileName, {
    required bool isXapk,
  }) async {
    _sessionManagerStore.updateDeviceTask(
      serial,
      type: DeviceTaskType.install,
      status: 'Đang cài $fileName...',
    );

    if (isXapk) {
      await _adbDataSource.installXapk(
        serial,
        path,
        onStatus: (status) {
          if (!_isCanceled(serial)) {
            _sessionManagerStore.updateDeviceTask(
              serial,
              type: DeviceTaskType.install,
              status: status,
            );
          }
        },
      );
    } else {
      await _adbDataSource.installPackage(serial, path);
    }

    if (_isCanceled(serial)) return;

    _sessionManagerStore.updateDeviceTask(
      serial,
      type: DeviceTaskType.install,
      status: 'Đã cài đặt xong!',
      phase: DeviceTaskPhase.success,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  Future<void> _handleDefaultPush(String serial, List<String> paths) async {
    _sessionManagerStore.updateDeviceTask(
      serial,
      type: DeviceTaskType.push,
      status: 'Đang đẩy ${paths.length} file...',
    );
    await _scrcpyService.pushFiles(serial, paths);
    if (_isCanceled(serial)) return;
    _sessionManagerStore.updateDeviceTask(
      serial,
      type: DeviceTaskType.push,
      status: 'Đã gửi thành công!',
      phase: DeviceTaskPhase.success,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
  }
}
