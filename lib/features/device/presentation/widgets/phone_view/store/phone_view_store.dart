import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/constants/ui_constants.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/core/utils/android_key_codes.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import 'package:scraki/features/dashboard/presentation/stores/dashboard_store.dart';
import 'package:scraki/features/device/data/datasources/scrcpy_client.dart';
import 'package:scraki/features/device/data/datasources/scrcpy_service.dart';
import 'package:scraki/features/device/data/datasources/video_worker_manager.dart';
import 'package:scraki/features/device/data/utils/scrcpy_input_serializer.dart';
import 'package:scraki/features/device/domain/entities/mirror_session.dart';
import 'package:scraki/features/device/domain/entities/scrcpy_options.dart';
import 'package:scraki/features/device/presentation/widgets/native_video_decoder/native_video_decoder_service.dart';
import 'package:scraki/features/device/domain/services/i_tiktok_post_service.dart';
import 'package:scraki/features/device/data/datasources/adb_remote_data_source.dart';

part 'phone_view_store.g.dart';

/// Dashboard tab indices
class DashboardTabs {
  static const int devices = 0; // PhoneView grid/floating
  static const int videoEditor = 2; // Video Poster Playground
}

/// Performance profiles for different viewing modes.
class PerformanceProfiles {
  static const grid = ScrcpyOptions(
    bitRate: 200000, // 1 Mbps
    maxFps: 10,
    control: false,
    maxSize: 360,
  );

  static const floating = ScrcpyOptions(
    bitRate: 2500000, // 25 Mbps
    maxFps: 60,
    control: true,
  );
}

// ignore: library_private_types_in_public_api
class PhoneViewStore = _PhoneViewStore with _$PhoneViewStore;

/// Store responsible for managing screen mirroring sessions and input handling.
abstract class _PhoneViewStore with Store, SessionManagerStoreMixin {
  final ScrcpyService _scrcpyService = getIt<ScrcpyService>();
  final VideoWorkerManager _workerManager = getIt<VideoWorkerManager>();
  final DashboardStore _dashboardStore = getIt<DashboardStore>();
  final ITikTokPostService _tikTokService = getIt<ITikTokPostService>();
  final IAdbRemoteDataSource _adbDataSource = getIt<IAdbRemoteDataSource>();
  final String serial;
  final bool isFloatingView;

  late final String sessionId;

  /// True khi người dùng đang ở tab Devices.
  @computed
  bool get isOnDevicesTab =>
      _dashboardStore.selectedIndex == DashboardTabs.devices;

  ReactionDisposer? _floatingDisposer;
  int _retryCount = 0;

  _PhoneViewStore(this.serial, this.isFloatingView) {
    sessionId = isFloatingView ? '${serial}_floating' : '${serial}_grid';
    initializing();
  }

  void initializing() async {
    try {
      if (isFloatingView) {
        _floatingDisposer = reaction((_) => isFloating, (isFloating) async {
          if (isFloating) {
            await startMirroring();
          }
        }, fireImmediately: true);
      } else {
        await startMirroring();
      }
    } catch (e) {
      logger.e(
        '[PhoneView] Failed to start mirroring or setting reactions',
        error: e,
      );
    }
  }

  void dispose() {
    setVisibility(serial, false, isFloating: isFloatingView);
    _floatingDisposer?.call();
    stopMirroring();
  }

  // ═══════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  @computed
  MirrorSession? get session => sessionManagerStore.activeSessions[sessionId];

  // ═══════════════════════════════════════════════════════════════
  // UI STATES
  // ═══════════════════════════════════════════════════════════════

  @computed
  bool get isFloating => floatingSerial == serial;

  @observable
  bool isLoading = false;

  @observable
  bool isConnecting = false;

  @observable
  bool isDraggingFile = false;
 
  @observable
  bool isDraggingApk = false;
 
  @observable
  String? error;

  @computed
  DeviceTaskState? get activeTask => sessionManagerStore.activeTasks[serial];

  @computed
  bool get isTaskRunning => activeTask != null;

  @computed
  String get taskStatus => activeTask?.status ?? '';

  @computed
  String get taskLabel => activeTask?.label ?? '';

  @observable
  bool hasLostConnection = false;

  @observable
  DateTime? lastTapTimes;

  @readonly
  bool _isVisible = false;

  // ═══════════════════════════════════════════════════════════════
  // FLOATING WINDOW
  // ═══════════════════════════════════════════════════════════════

  @computed
  String? get floatingSerial => sessionManagerStore.floatingSerial;
  set floatingSerial(String? serial) =>
      sessionManagerStore.floatingSerial = serial;

  @computed
  bool get isFloatingVisible => sessionManagerStore.isFloatingVisible;

  @computed
  bool get isBlockedByFloating =>
      !isFloatingView && sessionManagerStore.isFloatingVisible;

  @action
  void toggleFloating(String? serial) {
    if (floatingSerial == serial) {
      floatingSerial = null;
    } else {
      floatingSerial = serial;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // VISIBILITY MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  @action
  void setVisibility(String serial, bool isVisible, {bool isFloating = false}) {
    if (isFloating == isFloatingView) {
      _isVisible = isVisible || isFloating;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MIRRORING LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  @action
  Future<MirrorSession> startMirroring([ScrcpyOptions? options]) async {
    runInAction(() {
      isLoading = true;
      error = null;
      hasLostConnection = false;
      isConnecting = true;
    });

    try {
      final isOnline = await _scrcpyService.isDeviceConnected(serial);
      if (!isOnline) {
        throw 'Device $serial is not connected or unauthorized.';
      }

      if (session != null) return session!;

      final scrcpyOptions = options ?? (isFloatingView ? PerformanceProfiles.floating : PerformanceProfiles.grid);

      final resolutionFuture = _workerManager.waitForEvent(sessionId, 'resolution_ready');

      final portsData = await _workerManager.startMirroring(
        sessionId,
        listener: (event) {
          if (event.type == 'connection_lost') {
            runInAction(() {
              _workerManager.stopMirroring(sessionId);
              sessionManagerStore.activeSessions.remove(sessionId);
              hasLostConnection = true;
            });

            if (_retryCount < 3) {
              final delaySeconds = [1, 2, 5][_retryCount];
              _retryCount++;
              Timer(Duration(seconds: delaySeconds), () {
                if (_isVisible || isFloatingView) startMirroring();
              });
            }
          }
        },
      );
      final adbPort = portsData['adbPort'] as int;
      final proxyPort = portsData['proxyPort'] as int;

      final serverData = await _scrcpyService.initServer(serial, scrcpyOptions, adbPort);
      final scid = serverData.scid;

      final resolutionData = await resolutionFuture;
      final width = resolutionData['width'] as int;
      final height = resolutionData['height'] as int;

      final url = 'tcp://127.0.0.1:$proxyPort';
      final mirrorSession = MirrorSession(
        videoUrl: url,
        width: width,
        height: height,
        port: adbPort,
        scid: scid,
        decoderService: NativeVideoDecoderService(),
      );

      await mirrorSession.decoderService.start(url);

      runInAction(() {
        sessionManagerStore.activeSessions[sessionId] = mirrorSession;
        isLoading = false;
        _retryCount = 0;
      });

      return mirrorSession;
    } catch (e, stackTrace) {
      logger.e('[SessionManagerStore] ERROR during mirroring setup', error: e, stackTrace: stackTrace);
      runInAction(() {
        error = 'Mirror failed: $e';
        isLoading = false;
      });
      rethrow;
    } finally {
      runInAction(() => isConnecting = false);
    }
  }

  @action
  Future<void> stopMirroring() async {
    final currentSession = session;
    if (currentSession != null) {
      await currentSession.decoderService.stop(currentSession.videoUrl);
      try {
        await getIt<ScrcpyClient>().removeTunnel(serial, currentSession.scid);
      } catch (e) {
        logger.w('[SessionManagerStore] Failed to remove tunnel', error: e);
      }
    }

    sessionManagerStore.activeSessions.remove(sessionId);
    _workerManager.stopMirroring(sessionId);

    final hasOtherSessions = sessionManagerStore.activeSessions.keys.any((k) => k.startsWith('${serial}_'));
    if (!hasOtherSessions) {
      try {
        await _scrcpyService.killServer(serial);
      } catch (e) {
        logger.w('[SessionManagerStore] Error cleaning up server', error: e);
      }
    }
  }

  @action
  void setDecoderError(String serial, String error) {
    this.error = 'Decoder error: $error';
  }

  // ═══════════════════════════════════════════════════════════════
  // INPUT HANDLING
  // ═══════════════════════════════════════════════════════════════

  @action
  void handlePointerEvent(String serial, PointerEvent event, int action, int nativeWidth, int nativeHeight) {
    final x = event.localPosition.dx.toInt().clamp(0, nativeWidth);
    final y = event.localPosition.dy.toInt().clamp(0, nativeHeight);
    sendTouch(sessionId, x, y, action, nativeWidth, nativeHeight, buttons: event.buttons);
  }

  void sendTouch(String sessionId, int x, int y, int action, int width, int height, {int buttons = UIConstants.defaultTouchButtons}) {
    if (x < 0 || y < 0) return;
    final message = TouchControlMessage(action: action, x: x, y: y, width: width, height: height, buttons: buttons, pointerId: 0);
    _workerManager.sendControl(sessionId, message.serialize());
  }

  @action
  void handleScrollEvent(String serial, PointerScrollEvent event, int nativeWidth, int nativeHeight) {
    const double sensitivity = 15.0;
    _scrollAccumulatorX -= event.scrollDelta.dx * sensitivity;
    _scrollAccumulatorY -= event.scrollDelta.dy * sensitivity;

    int hScroll = _scrollAccumulatorX.truncate();
    int vScroll = _scrollAccumulatorY.truncate();

    if (hScroll == 0 && vScroll == 0) return;

    _scrollAccumulatorX -= hScroll;
    _scrollAccumulatorY -= vScroll;

    final x = event.localPosition.dx.toInt().clamp(0, nativeWidth);
    final y = event.localPosition.dy.toInt().clamp(0, nativeHeight);
    sendScroll(sessionId, x, y, nativeWidth, nativeHeight, hScroll, vScroll);
  }

  double _scrollAccumulatorX = 0;
  double _scrollAccumulatorY = 0;

  void sendScroll(String sessionId, int x, int y, int width, int height, int hScroll, int vScroll) {
    if (x < 0 || y < 0) return;
    final message = ScrollControlMessage(x: x, y: y, width: width, height: height, hScroll: hScroll, vScroll: vScroll);
    _workerManager.sendControl(sessionId, message.serialize());
  }

  @action
  void handleKeyboardEvent(String serial, KeyEvent event) {
    int action = -1;
    int repeat = 0;

    if (event is KeyDownEvent) action = 0;
    else if (event is KeyRepeatEvent) { action = 0; repeat = 1; }
    else if (event is KeyUpEvent) action = 1;

    if (action == -1) return;

    final isModified = HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed;
    if (isModified && action == 0 && repeat == 0 && event.logicalKey == LogicalKeyboardKey.keyV) {
      handlePaste(serial);
      return;
    }

    final androidCode = AndroidKeyCodes.getKeyCode(event.logicalKey);
    if (androidCode != AndroidKeyCodes.kUnknown) {
      sendKey(serial, androidCode, action, repeat: repeat, metaState: _getAndroidMetaState());
    }
  }

  void sendKey(String serial, int keyCode, int action, {int repeat = 0, int metaState = 0}) {
    if (keyCode == 0) return;
    final message = KeyControlMessage(action: action, keyCode: keyCode, repeat: repeat, metaState: metaState);
    _workerManager.sendControl(sessionId, message.serialize());
  }

  void sendKeyByAdb(int keyCode) {
    if (keyCode == 0) return;
    _adbDataSource.sendKeyEvent(serial, keyCode);
  }

  int _getAndroidMetaState() {
    int meta = 0;
    if (HardwareKeyboard.instance.isShiftPressed) meta |= AndroidKeyCodes.kMetaShiftOn;
    if (HardwareKeyboard.instance.isControlPressed) meta |= AndroidKeyCodes.kMetaCtrlOn;
    if (HardwareKeyboard.instance.isAltPressed) meta |= AndroidKeyCodes.kMetaAltOn;
    if (HardwareKeyboard.instance.isMetaPressed) meta |= AndroidKeyCodes.kMetaCtrlOn;
    return meta;
  }

  @action
  Future<void> handlePaste(String serial) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) setClipboard(serial, text, paste: true);
  }

  void setClipboard(String serial, String text, {bool paste = false}) {
    final message = SetClipboardControlMessage(text, paste: paste);
    _workerManager.sendControl(sessionId, message.serialize());
  }

  void sendText(String serial, String text) {
    if (text.isEmpty) return;
    final message = InjectTextControlMessage(text);
    _workerManager.sendControl(sessionId, message.serialize());
  }

  // ═══════════════════════════════════════════════════════════════
  // FILE OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  @action
  void setDragging(String serial, bool isDragging, {bool isApk = false}) {
    if (!isOnDevicesTab) return;
    isDraggingFile = isDragging;
    isDraggingApk = isDragging ? isApk : false;
  }

  @action
  Future<void> uploadFiles(String serial, List<String> paths) async {
    if (paths.isEmpty) return;

    final isVideo = paths.every((p) {
      final ext = p.toLowerCase().split('.').last;
      return const {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'ts', 'm4v', 'flv', 'wmv'}.contains(ext);
    });
    final isApk = paths.every((p) => p.toLowerCase().endsWith('.apk'));
    
    if (!isOnDevicesTab && !isVideo && !isApk) return;

    try {
      final fileName = paths.first.split(RegExp(r'[/\\]')).last;
      if (isVideo) {
        sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.videoGen, status: 'Đang đẩy $fileName...');
        await _tikTokService.openTikTokCreate(serial, paths.first);
        sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.videoGen, status: 'Sẵn sàng!', phase: DeviceTaskPhase.success);
        await Future<void>.delayed(const Duration(seconds: 2));
      } else if (isApk) {
        sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.install, status: 'Đang cài $fileName...');
        await _adbDataSource.installPackage(serial, paths.first);
        sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.install, status: 'Đã cài đặt xong!', phase: DeviceTaskPhase.success);
        await Future<void>.delayed(const Duration(seconds: 2));
      } else {
        sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.push, status: 'Đang đẩy ${paths.length} file...');
        await _scrcpyService.pushFiles(serial, paths);
        sessionManagerStore.updateDeviceTask(serial, type: DeviceTaskType.push, status: 'Đã gửi thành công!', phase: DeviceTaskPhase.success);
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      logger.e('[PhoneViewStore] Task failed', error: e);
      sessionManagerStore.updateDeviceTask(
        serial,
        type: isApk ? DeviceTaskType.install : (isVideo ? DeviceTaskType.videoGen : DeviceTaskType.push),
        status: 'Lỗi: $e',
        phase: DeviceTaskPhase.failed,
      );
      await Future<void>.delayed(const Duration(seconds: 3));
    } finally {
      sessionManagerStore.clearDeviceTask(serial);
    }
  }

  @action
  void cancelActiveTask() {
    sessionManagerStore.clearDeviceTask(serial);
  }

  @action
  bool checkDoubleTap(String serial) {
    final now = DateTime.now();
    if (lastTapTimes != null && now.difference(lastTapTimes!) < UIConstants.doubleTapTimeout) {
      lastTapTimes = null;
      toggleFloating(serial);
      return true;
    } else {
      lastTapTimes = now;
      return false;
    }
  }
}
