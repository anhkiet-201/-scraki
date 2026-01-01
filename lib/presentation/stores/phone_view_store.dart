import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import '../../core/di/injection.dart';
import '../../data/datasources/scrcpy_client.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/entities/scrcpy_options.dart';
import '../../domain/repositories/device_repository.dart';
import '../../data/services/scrcpy_service.dart';
import '../../data/utils/scrcpy_input_serializer.dart';
import '../../data/services/video_worker_manager.dart';
import '../../domain/entities/mirror_session.dart';
import '../../core/utils/logger.dart';
import '../widgets/device/native_video_decoder/native_video_decoder_service.dart';

part 'phone_view_store.g.dart';

@lazySingleton
class PhoneViewStore = _PhoneViewStore with _$PhoneViewStore;

/// Store responsible for managing device-related state and mirroring sessions.
///
/// It orchestrates the process of loading devices, starting mirroring,
/// and handling input events.
abstract class _PhoneViewStore with Store {
  final DeviceRepository _repository;
  final ScrcpyService _scrcpyService;
  final VideoWorkerManager _workerManager;

  _PhoneViewStore(this._repository, this._scrcpyService, this._workerManager);

  @observable
  ObservableList<DeviceEntity> devices = ObservableList<DeviceEntity>();

  @observable
  ObservableSet<String> selectedSerials = ObservableSet<String>();

  @observable
  bool isBroadcastingMode = false;

  @observable
  ObservableFuture<void>? loadDevicesFuture;

  @observable
  String? errorMessage;

  @observable
  ObservableSet<String> visibleGridSerials = ObservableSet<String>();

  @observable
  ObservableSet<String> visibleFloatingSerials = ObservableSet<String>();

  bool isDeviceVisible(String serial) =>
      visibleGridSerials.contains(serial) ||
      visibleFloatingSerials.contains(serial);

  @observable
  String? floatingSerial;

  @observable
  ObservableMap<String, MirrorSession> activeSessions =
      ObservableMap<String, MirrorSession>();

  @observable
  ObservableMap<String, bool> isPushingFile = ObservableMap<String, bool>();

  @observable
  ObservableMap<String, bool> isDraggingFile = ObservableMap<String, bool>();

  @observable
  ObservableMap<String, bool> lostConnectionSerials =
      ObservableMap<String, bool>();

  @observable
  ObservableMap<String, bool> isConnecting = ObservableMap<String, bool>();

  @computed
  double get deviceAspectRatio {
    if (activeSessions.isEmpty) return 0.5625; // Default 9:16

    // Use the aspect ratio of the first active session for the whole grid
    final firstSession = activeSessions.values.first;
    if (firstSession.width > 0 && firstSession.height > 0) {
      return firstSession.width / firstSession.height;
    }
    return 0.5625;
  }

  @computed
  bool get isLoading => loadDevicesFuture?.status == FutureStatus.pending;

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

  @action
  void toggleBroadcasting() {
    isBroadcastingMode = !isBroadcastingMode;
  }

  @action
  void toggleDeviceSelection(String serial) {
    if (selectedSerials.contains(serial)) {
      selectedSerials.remove(serial);
    } else {
      selectedSerials.add(serial);
    }
  }

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
  void setVisibility(String serial, bool isVisible, {bool isFloating = false}) {
    final wasVisible = isDeviceVisible(serial);

    if (isFloating) {
      if (isVisible)
        visibleFloatingSerials.add(serial);
      else
        visibleFloatingSerials.remove(serial);
    } else {
      if (isVisible)
        visibleGridSerials.add(serial);
      else
        visibleGridSerials.remove(serial);
    }

    final isNowVisible = isDeviceVisible(serial);

    if (wasVisible != isNowVisible) {
      if (isNowVisible) {
        _workerManager.resumeMirroring(serial);
      } else {
        _workerManager.pauseMirroring(serial);
      }
    }
  }

  @action
  Future<MirrorSession> startMirroring(
    String serial, [
    ScrcpyOptions? options,
  ]) async {
    runInAction(() {
      errorMessage = null;
      lostConnectionSerials.remove(serial);
      isConnecting[serial] = true;
    });

    try {
      // 0. Check if device is actually connected via ADB
      final isOnline = await _scrcpyService.isDeviceConnected(serial);
      if (!isOnline) {
        throw 'Device $serial is not connected or unauthorized. Please check your cable/ADB status.';
      }

      // Return existing session if available
      if (activeSessions.containsKey(serial)) {
        logger.i('[DeviceStore] Using existing mirroring session for $serial');
        return activeSessions[serial]!;
      }

      logger.i('[DeviceStore] Starting new mirroring session for $serial');
      const scrcpyOptions = ScrcpyOptions();

      // 1. Khởi tạo Isolate Worker and get ports
      final resolutionFuture = _workerManager.waitForEvent(
        serial,
        'resolution_ready',
      );

      final portsData = await _workerManager.startMirroring(
        serial,
        listener: (event) {
          if (event.type == 'connection_lost') {
            logger.w('[DeviceStore] Connection lost for $serial');
            runInAction(() {
              _workerManager.stopMirroring(serial);
              activeSessions.remove(serial);
              lostConnectionSerials[serial] = true;
            });
          }
        },
      );
      final adbPort = portsData['adbPort'] as int;
      final proxyPort = portsData['proxyPort'] as int;

      // 2. Setup Scrcpy Server with the allocated adbPort
      await _scrcpyService.initServer(serial, scrcpyOptions, adbPort);

      // 3. Chờ Resolution Header được parse xong trong Isolate
      final resolutionData = await resolutionFuture;
      final width = resolutionData['width'] as int;
      final height = resolutionData['height'] as int;

      // 4. Create Mirror Session
      final url = 'tcp://127.0.0.1:$proxyPort';
      final mirrorSession = MirrorSession(
        videoUrl: url,
        width: width,
        height: height,
        decoderService: NativeVideoDecoderService(),
      );

      // Pre-warm decoder
      await mirrorSession.decoderService.start(url);

      runInAction(() {
        activeSessions[serial] = mirrorSession;
      });

      return mirrorSession;
    } catch (e, stackTrace) {
      logger.e(
        '[DeviceStore] ERROR during mirroring setup',
        error: e,
        stackTrace: stackTrace,
      );
      runInAction(() => errorMessage = 'Mirror failed: $e');
      rethrow;
    } finally {
      runInAction(() => isConnecting[serial] = false);
    }
  }

  @action
  Future<void> stopMirroring(String serial) async {
    logger.i('[DeviceStore] Stopping mirroring for $serial');
    final session = activeSessions[serial];
    if (session != null) {
      await session.decoderService.stop(session.videoUrl);
    }
    activeSessions.remove(serial);
    _workerManager.stopMirroring(serial);
    _scrcpyService.cleanup(serial);

    try {
      await getIt<ScrcpyClient>().removeTunnel(serial, 0);
      await _scrcpyService.killServer(serial);
    } catch (e) {
      logger.w('[DeviceStore] Error cleaning up', error: e);
    }
  }

  @action
  Future<void> connectTcp(String ip, int port) async {
    errorMessage = null;
    final result = await _repository.connectTcp(ip, port);
    await result.fold(
      (failure) async => runInAction(() => errorMessage = failure.message),
      (_) async => await loadDevices(),
    );
  }

  @action
  Future<void> disconnect(String serial) async {
    errorMessage = null;
    final result = await _repository.disconnectDevice(serial);
    await result.fold(
      (failure) async => runInAction(() => errorMessage = failure.message),
      (_) async => await loadDevices(),
    );
  }

  void sendTouch(
    String serial,
    int x,
    int y,
    int action,
    int width,
    int height, {
    int buttons = 0,
  }) {
    if (x < 0 || y < 0) return;

    final message = TouchControlMessage(
      action: action,
      x: x,
      y: y,
      width: width,
      height: height,
      buttons: buttons,
      pointerId: 0, // Mouse always 0
    );

    _workerManager.sendControl(serial, message.serialize());
  }

  void sendScroll(
    String serial,
    int x,
    int y,
    int width,
    int height,
    int hScroll,
    int vScroll,
  ) {
    if (x < 0 || y < 0) return;

    final message = ScrollControlMessage(
      x: x,
      y: y,
      width: width,
      height: height,
      hScroll: hScroll,
      vScroll: vScroll,
    );

    _workerManager.sendControl(serial, message.serialize());
  }

  void sendKey(String serial, int keyCode, int action, {int metaState = 0}) {
    if (keyCode == 0) return;

    final message = KeyControlMessage(
      action: action, // 0=Down, 1=Up
      keyCode: keyCode,
      metaState: metaState,
    );

    _workerManager.sendControl(serial, message.serialize());
  }

  void sendText(String serial, String text) {
    if (text.isEmpty) return;
    final message = InjectTextControlMessage(text);
    _workerManager.sendControl(serial, message.serialize());
  }

  void setClipboard(String serial, String text, {bool paste = false}) {
    final message = SetClipboardControlMessage(text, paste: paste);
    _workerManager.sendControl(serial, message.serialize());
  }

  void handlePointerEvent(
    String serial,
    PointerEvent event,
    int action,
    int nativeWidth,
    int nativeHeight,
  ) {
    final x = event.localPosition.dx.toInt().clamp(0, nativeWidth);
    final y = event.localPosition.dy.toInt().clamp(0, nativeHeight);
    final buttons = event.buttons;

    sendTouch(
      serial,
      x,
      y,
      action,
      nativeWidth,
      nativeHeight,
      buttons: buttons,
    );
  }

  void handleScrollEvent(
    String serial,
    PointerScrollEvent event,
    int nativeWidth,
    int nativeHeight,
  ) {
    final x = event.localPosition.dx.toInt().clamp(0, nativeWidth);
    final y = event.localPosition.dy.toInt().clamp(0, nativeHeight);

    final hScroll = -(event.scrollDelta.dx / 20).round();
    final vScroll = -(event.scrollDelta.dy / 20).round();

    if (hScroll == 0 && vScroll == 0) return;

    sendScroll(serial, x, y, nativeWidth, nativeHeight, hScroll, vScroll);
  }

  @action
  void setDragging(String serial, bool isDragging) {
    if (isDragging) {
      isDraggingFile[serial] = true;
    } else {
      isDraggingFile.remove(serial);
    }
  }

  @action
  Future<void> uploadFiles(String serial, List<String> paths) async {
    if (paths.isEmpty) return;

    runInAction(() => isPushingFile[serial] = true);
    try {
      await _scrcpyService.pushFiles(serial, paths);
      logger.i(
        '[PhoneViewStore] Successfully pushed ${paths.length} files to $serial',
      );
    } catch (e) {
      logger.e('[PhoneViewStore] Failed to push files to $serial', error: e);
      runInAction(() => errorMessage = 'Failed to push files: $e');
    } finally {
      runInAction(() => isPushingFile[serial] = false);
    }
  }
}
