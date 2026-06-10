import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:scraki/core/stores/session_manager_store.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/data/datasources/adb_remote_data_source.dart';
import 'package:scraki/features/device/data/datasources/scrcpy_service.dart';
import 'package:scraki/features/device/domain/services/i_device_task_service.dart';
import 'package:scraki/features/device/domain/services/i_tiktok_post_service.dart';

@LazySingleton(as: IDeviceTaskService)
class DeviceTaskServiceImpl implements IDeviceTaskService {
  final SessionManagerStore _sessionManagerStore;
  final ITikTokPostService _tikTokService;
  final IAdbRemoteDataSource _adbDataSource;
  final ScrcpyService _scrcpyService;

  DeviceTaskServiceImpl(
    this._sessionManagerStore,
    this._tikTokService,
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
      if (task.type != DeviceTaskType.script && task.type != DeviceTaskType.command) {
        _sessionManagerStore.updateDeviceTask(
          serial,
          type: task.type,
          status: 'Đã hủy!',
          phase: DeviceTaskPhase.failed,
        );
        Future.delayed(const Duration(seconds: 2), () {
          final currentTask = _sessionManagerStore.activeTasks[serial];
          if (currentTask != null && currentTask.phase == DeviceTaskPhase.failed && currentTask.status == 'Đã hủy!') {
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
    if (paths.isEmpty) return;

    final isVideo = paths.every((p) {
      final ext = p.toLowerCase().split('.').last;
      return const {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'ts', 'm4v', 'flv', 'wmv'}.contains(ext);
    });
    final isApk = paths.every((path) => path.toLowerCase().endsWith('.apk'));
    final isXapk = paths.every((path) => path.toLowerCase().endsWith('.xapk'));

    try {
      final fileName = p.basename(paths.first);
      
      // Check if it's a "Set_" directory drop (Image Poster Set)
      final isSetDir = paths.length == 1 && Directory(paths.first).existsSync() && fileName.startsWith('Set_');

      if (isSetDir) {
        _sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.imagePost, status: 'Đang đẩy bộ ảnh $fileName...');
        
        await _tikTokService.openTikTokPostImages(serial, paths.first);
        
        if (_isCanceled(serial)) return;
        _sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.imagePost, status: 'Sẵn sàng!', phase: DeviceTaskPhase.success);
        await Future<void>.delayed(const Duration(seconds: 2));
      } else if (isVideo) {
        if (fileName.startsWith('tik_final_')) {
          _sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.videoGen, status: 'Đang đẩy $fileName...');
          await _tikTokService.openTikTokCreate(serial, paths.first);
          if (_isCanceled(serial)) return;
          _sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.videoGen, status: 'Sẵn sàng!', phase: DeviceTaskPhase.success);
        } else {
          _sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.push, status: 'Đang đẩy $fileName...');
          await _scrcpyService.pushFiles(serial, paths);
          if (_isCanceled(serial)) return;
          _sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.push, status: 'Đã gửi thành công!', phase: DeviceTaskPhase.success);
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      } else if (isApk || isXapk) {
        _sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.install, status: 'Đang cài $fileName...');
        if (isXapk) {
           await _adbDataSource.installXapk(
             serial, 
             paths.first, 
             onStatus: (status) {
               if (!_isCanceled(serial)) {
                 _sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.install, status: status);
               }
             },
           );
        } else {
           await _adbDataSource.installPackage(serial, paths.first);
        }
        if (_isCanceled(serial)) return;
        _sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.install, status: 'Đã cài đặt xong!', phase: DeviceTaskPhase.success);
        await Future<void>.delayed(const Duration(seconds: 2));
      } else {
        _sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.push, status: 'Đang đẩy ${paths.length} file...');
        await _scrcpyService.pushFiles(serial, paths);
        if (_isCanceled(serial)) return;
        _sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.push, status: 'Đã gửi thành công!', phase: DeviceTaskPhase.success);
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      logger.e('[DeviceTaskService] Task failed', error: e);
      if (_isCanceled(serial)) return;
      _sessionManagerStore.updateDeviceTask(
        serial,
        type: (isApk || isXapk) ? DeviceTaskType.install : (isVideo ? DeviceTaskType.videoGen : DeviceTaskType.push),
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
}
