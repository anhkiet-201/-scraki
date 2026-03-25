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
    bitRate: 100000, // 1 Mbps
    maxFps: 10,
    control: false,
    maxSize: 360,
  );

  static const floating = ScrcpyOptions(
    bitRate: 4000000, // 8 Mbps
    maxFps: 60,
    control: true,
  );
}

// ignore: library_private_types_in_public_api
class PhoneViewStore = _PhoneViewStore with _$PhoneViewStore;

/// Store responsible for managing screen mirroring sessions and input handling.
///
/// Handles:
/// - Mirroring lifecycle (start/stop)
/// - Active sessions management
/// - Input events (touch, keyboard, scroll)
/// - File operations (drag & drop)
/// - Clipboard operations
/// - Double-tap floating detection
/// - UI states (loading, errors, connection status)
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
  /// Dùng để chặn kéo thả file khi ở tab khác.
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
        // Floating view follows visibility
        _floatingDisposer = reaction((_) => isFloating, (isFloating) async {
          if (isFloating) {
            await startMirroring();
          }
        }, fireImmediately: true);
      } else {
        // Grid view always starts mirroring
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
  double get taskProgress => activeTask?.progress ?? 0.0;
 
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

  /// True khi floating window đang mở VÀ view hiện tại là grid
  /// (tức là view đang bị floating che khuất).
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
    // Only update visibility for the current session type
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
      // Check if device is connected
      final isOnline = await _scrcpyService.isDeviceConnected(serial);
      if (!isOnline) {
        throw 'Device $serial is not connected or unauthorized. Please check your cable/ADB status.';
      }

      // Return existing session if available
      if (session != null) {
        logger.i(
          '[SessionManagerStore] Using existing mirroring session for $sessionId',
        );
        return session!;
      }

      logger.i(
        '[SessionManagerStore] Starting new mirroring session for $sessionId',
      );
      final scrcpyOptions =
          options ??
          (isFloatingView
              ? PerformanceProfiles.floating
              : PerformanceProfiles.grid);

      // Initialize worker and get ports
      final resolutionFuture = _workerManager.waitForEvent(
        sessionId,
        'resolution_ready',
      );

      final portsData = await _workerManager.startMirroring(
        sessionId,
        listener: (event) {
          if (event.type == 'connection_lost') {
            logger.w('[SessionManagerStore] Connection lost for $sessionId');
            runInAction(() {
              _workerManager.stopMirroring(sessionId);
              sessionManagerStore.activeSessions.remove(sessionId);
              hasLostConnection = true;
            });

            // Auto-Reconnect Logic
            if (_retryCount < 3) {
              final delaySeconds = [1, 2, 5][_retryCount];
              _retryCount++;
              logger.i('[PhoneViewStore] Auto-reconnect: retry $_retryCount in ${delaySeconds}s');
              Timer(Duration(seconds: delaySeconds), () {
                if (_isVisible || isFloatingView) {
                  startMirroring();
                }
              });
            }
          }
        },
      );
      final adbPort = portsData['adbPort'] as int;
      final proxyPort = portsData['proxyPort'] as int;

      // Setup Scrcpy Server
      final serverData = await _scrcpyService.initServer(
        serial,
        scrcpyOptions,
        adbPort,
      );
      final scid = serverData.scid;

      // Wait for resolution
      final resolutionData = await resolutionFuture;
      final width = resolutionData['width'] as int;
      final height = resolutionData['height'] as int;

      // Create Mirror Session
      final url = 'tcp://127.0.0.1:$proxyPort';
      final mirrorSession = MirrorSession(
        videoUrl: url,
        width: width,
        height: height,
        port: adbPort,
        scid: scid,
        decoderService: NativeVideoDecoderService(),
      );

      // Pre-warm decoder
      await mirrorSession.decoderService.start(url);

      runInAction(() {
        sessionManagerStore.activeSessions[sessionId] = mirrorSession;
        isLoading = false;
        _retryCount = 0; // Reset retry count on success
      });

      return mirrorSession;
    } catch (e, stackTrace) {
      logger.e(
        '[SessionManagerStore] ERROR during mirroring setup for $sessionId',
        error: e,
        stackTrace: stackTrace,
      );
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
    logger.i('[SessionManagerStore] Stopping mirroring for $sessionId');
    final currentSession = session;
    if (currentSession != null) {
      await currentSession.decoderService.stop(currentSession.videoUrl);

      // Cleanup ADB tunnel for this specific scid
      try {
        await getIt<ScrcpyClient>().removeTunnel(serial, currentSession.scid);
      } catch (e) {
        logger.w(
          '[SessionManagerStore] Failed to remove tunnel for $sessionId',
          error: e,
        );
      }
    }

    sessionManagerStore.activeSessions.remove(sessionId);
    _workerManager.stopMirroring(sessionId);

    // Only kill server if NO OTHER sessions for this serial exist
    final hasOtherSessions = sessionManagerStore.activeSessions.keys.any(
      (k) => k.startsWith('${serial}_'),
    );
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
    error = 'Decoder error: $error';
  }

  // ═══════════════════════════════════════════════════════════════
  // INPUT HANDLING - Touch Events
  // ═══════════════════════════════════════════════════════════════

  @action
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
      sessionId,
      x,
      y,
      action,
      nativeWidth,
      nativeHeight,
      buttons: buttons,
    );
  }

  void sendTouch(
    String sessionId,
    int x,
    int y,
    int action,
    int width,
    int height, {
    int buttons = UIConstants.defaultTouchButtons,
  }) {
    if (x < 0 || y < 0) return;

    final message = TouchControlMessage(
      action: action,
      x: x,
      y: y,
      width: width,
      height: height,
      buttons: buttons,
      pointerId: 0,
    );

    _workerManager.sendControl(sessionId, message.serialize());
  }

  // ═══════════════════════════════════════════════════════════════
  // INPUT HANDLING - Scroll Events
  // ═══════════════════════════════════════════════════════════════

  double _scrollAccumulatorX = 0;
  double _scrollAccumulatorY = 0;

  @action
  void handleScrollEvent(
    String serial,
    PointerScrollEvent event,
    int nativeWidth,
    int nativeHeight,
  ) {
    final x = event.localPosition.dx.toInt().clamp(0, nativeWidth);
    final y = event.localPosition.dy.toInt().clamp(0, nativeHeight);

    // Accumulate scroll deltas to handle precise scrolling (trackpads)
    const double sensitivity = 15.0;

    _scrollAccumulatorX -= event.scrollDelta.dx * sensitivity;
    _scrollAccumulatorY -= event.scrollDelta.dy * sensitivity;

    int hScroll = _scrollAccumulatorX.truncate();
    int vScroll = _scrollAccumulatorY.truncate();

    if (hScroll == 0 && vScroll == 0) return;

    // Remove the consumed integer part from accumulator
    _scrollAccumulatorX -= hScroll;
    _scrollAccumulatorY -= vScroll;

    sendScroll(sessionId, x, y, nativeWidth, nativeHeight, hScroll, vScroll);
  }

  void sendScroll(
    String sessionId,
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

    _workerManager.sendControl(sessionId, message.serialize());
  }

  // ═══════════════════════════════════════════════════════════════
  // INPUT HANDLING - Keyboard Events
  // ═══════════════════════════════════════════════════════════════

  @action
  void handleKeyboardEvent(String serial, KeyEvent event) {
    int action = -1;
    int repeat = 0;

    if (event is KeyDownEvent) {
      action = 0; // ACTION_DOWN
    } else if (event is KeyRepeatEvent) {
      action =
          0; // ACTION_DOWN (Repeat is just repeated DOWN events in Android)
      repeat = 1; // Mark as repeat
    } else if (event is KeyUpEvent) {
      action = 1; // ACTION_UP
    }

    if (action == -1) return;

    // Check for keyboard shortcuts
    final isModified =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    if (isModified && action == 0 && repeat == 0) {
      if (event.logicalKey == LogicalKeyboardKey.keyV) {
        handlePaste(serial);
        return;
      }
    }

    // Send regular key event
    final androidCode = AndroidKeyCodes.getKeyCode(event.logicalKey);
    if (androidCode != AndroidKeyCodes.kUnknown) {
      sendKey(
        serial,
        androidCode,
        action,
        repeat: repeat,
        metaState: _getAndroidMetaState(),
      );
    }
  }

  void sendKey(
    String serial,
    int keyCode,
    int action, {
    int repeat = 0,
    int metaState = 0,
  }) {
    if (keyCode == 0) return;

    final message = KeyControlMessage(
      action: action,
      keyCode: keyCode,
      repeat: repeat,
      metaState: metaState,
    );

    _workerManager.sendControl(sessionId, message.serialize());
  }

  void sendKeyByAdb(int keyCode) {
    if (keyCode == 0) return;
    _adbDataSource.sendKeyEvent(serial, keyCode);
  }

  int _getAndroidMetaState() {
    int meta = 0;
    if (HardwareKeyboard.instance.isShiftPressed) {
      meta |= AndroidKeyCodes.kMetaShiftOn;
    }
    if (HardwareKeyboard.instance.isControlPressed) {
      meta |= AndroidKeyCodes.kMetaCtrlOn;
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      meta |= AndroidKeyCodes.kMetaAltOn;
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      meta |= AndroidKeyCodes.kMetaCtrlOn; // Map Cmd to Ctrl for Android
    }
    return meta;
  }

  // ═══════════════════════════════════════════════════════════════
  // CLIPBOARD OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  @action
  Future<void> handlePaste(String serial) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      logger.i(
        '[SessionManagerStore] Pasting text to $serial: ${text.length} chars',
      );
      setClipboard(serial, text, paste: true);
    }
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
    // Only process drag events when on Devices tab (PhoneView dashboard)
    if (_dashboardStore.selectedIndex != DashboardTabs.devices) return;

    if (isDragging) {
      isDraggingFile = true;
      isDraggingApk = isApk;
    } else {
      isDraggingFile = false;
      isDraggingApk = false;
    }
  }

  @action
  Future<void> uploadFiles(String serial, List<String> paths) async {
    if (paths.isEmpty) return;

    final isVideo = paths.every((p) {
      final ext = p.toLowerCase().split('.').last;
      return const {
        'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'ts', 'm4v', 'flv', 'wmv',
      }.contains(ext);
    });
    final isApk = paths.every((p) => p.toLowerCase().endsWith('.apk'));
    
    logger.i('[PhoneViewStore] uploadFiles: serial=$serial, count=${paths.length}, isVideo=$isVideo, isApk=$isApk');

    // Only upload files when on Devices tab OR if it's a video (to trigger TikTok Create)
    // Hoặc nếu là APK (để cài đặt)
    if (_dashboardStore.selectedIndex != DashboardTabs.devices &&
        !isVideo &&
        !isApk) {
      logger.w('[PhoneViewStore] uploadFiles skipped: not on Devices tab (current: ${_dashboardStore.selectedIndex})');
      return;
    }

    try {
      if (isVideo) {
        // Handle TikTok Create for video files
        sessionManagerStore.updateDeviceTask(
          serial,
          type: DeviceTaskType.videoGen, // Reuse videoGen or define new? Let's use videoGen for consistent purple color
          status: 'Opening TikTok...',
        );
        await _tikTokService.openTikTokCreate(serial, paths.first);
        
        sessionManagerStore.updateDeviceTask(
          serial,
          type: DeviceTaskType.videoGen,
          status: 'Done!',
          progress: 1.0,
        );
        await Future<void>.delayed(const Duration(seconds: 1));
      } else if (isApk) {
        // Handle Silent APK installation (Persistent State)
        final fileName = paths.first.split(RegExp(r"[/\\]")).last;
        
        sessionManagerStore.updateDeviceTask(
          serial,
          type: DeviceTaskType.install,
          status: 'Starting installation...',
        );

        await _adbDataSource.installPackage(
          serial,
          paths.first,
          onProgress: (p) => sessionManagerStore.updateDeviceTask(
            serial,
            type: DeviceTaskType.install,
            progress: p,
            status: 'Streaming APK (${(p * 100).toInt()}%)...',
          ),
          onStatus: (s) => sessionManagerStore.updateDeviceTask(
            serial,
            type: DeviceTaskType.install,
            status: s,
          ),
        );
        
        logger.i('[PhoneViewStore] APK $fileName installed successfully');
        sessionManagerStore.updateDeviceTask(
          serial,
          type: DeviceTaskType.install,
          status: 'Success!',
          progress: 1.0,
        );
        await Future<void>.delayed(const Duration(seconds: 1));
      } else {
        // Normal file push via scrcpy
        sessionManagerStore.updateDeviceTask(
          serial,
          type: DeviceTaskType.push,
          status: 'Pushing ${paths.length} files...',
        );
        await _scrcpyService.pushFiles(serial, paths);
        logger.i(
          '[PhoneViewStore] Successfully pushed ${paths.length} files to $serial',
        );
        sessionManagerStore.updateDeviceTask(
          serial,
          type: DeviceTaskType.push,
          status: 'Success!',
          progress: 1.0,
        );
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      logger.e('[PhoneViewStore] Failed to process files for $serial', error: e);
      runInAction(() => error = 'Failed to process files: $e');
    } finally {
      sessionManagerStore.clearDeviceTask(serial);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DOUBLE-TAP DETECTION
  // ═══════════════════════════════════════════════════════════════

  @action
  bool checkDoubleTap(String serial) {
    final now = DateTime.now();

    if (lastTapTimes != null &&
        now.difference(lastTapTimes!) < UIConstants.doubleTapTimeout) {
      // Double tap detected
      lastTapTimes = null;
      toggleFloating(serial);
      logger.i('[SessionManagerStore] Double tap detected for $serial');
      return true;
    } else {
      // First tap or timeout
      lastTapTimes = now;
      return false;
    }
  }
}
