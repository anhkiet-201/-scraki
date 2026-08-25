import 'dart:async';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'package:scrcpy_flutter_plugin/scrcpy_flutter_plugin.dart' as plugin;
import 'package:scraki/core/constants/ui_constants.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/core/utils/android_key_codes.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/core/stores/session_manager_store.dart';
import 'package:scraki/features/dashboard/presentation/stores/dashboard_store.dart';
import 'package:scraki/features/device/data/services/scrcpy_controller_service.dart';
import 'package:scraki/features/device/domain/entities/mirror_session.dart';
import 'package:scraki/features/device/domain/services/device_shell.dart';
import 'package:scraki/features/device/domain/services/i_device_task_service.dart';
import 'package:scraki/features/device/data/datasources/adb_remote_data_source.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/script/presentation/stores/terminal_store.dart';
import 'package:scraki/core/auth/presentation/stores/app_auth_store.dart';

part 'phone_view_store.g.dart';

typedef PosterDropHandler = Future<File?> Function(PosterData);

/// Dashboard tab indices
class DashboardTabs {
  static const int devices = 0; // PhoneView grid/floating
  static const int videoEditor = 2; // Video Poster Playground
}

/// Performance profiles for different viewing modes.
class PerformanceProfiles {
  static plugin.ScrcpyOptions forGrid(String serial) => plugin.ScrcpyOptions(
        serial: serial,
        videoBitRate: 500000,
        maxFps: 10,
        control: true, // MUST be true to allow requesting keyframes on resume
        maxSize: 720,
        audio: false,
      );

  static plugin.ScrcpyOptions forFloating(String serial) => plugin.ScrcpyOptions(
        serial: serial,
        videoBitRate: 2500000,
        maxFps: 60,
        control: true,
        softwareDecoding: false
      );
}

// ignore: library_private_types_in_public_api
class PhoneViewStore = _PhoneViewStore with _$PhoneViewStore;

/// Store chịu trách nhiệm quản lý phiên mirror màn hình và xử lý input.
/// Sử dụng [ScrcpyController] từ scrcpy_flutter_plugin để thay thế
/// toàn bộ stack native tự viết (ScrcpyService, VideoWorkerManager, NativeVideoDecoderServiceImpl).
abstract class _PhoneViewStore with Store, SessionManagerStoreMixin {
  static Future<void> _globalStartQueue = Future.value();


  final ScrcpyControllerService _controllerService = getIt<ScrcpyControllerService>();
  final DashboardStore _dashboardStore = getIt<DashboardStore>();
  final IDeviceTaskService _deviceTaskService = getIt<IDeviceTaskService>();
  final IAdbRemoteDataSource _adbDataSource = getIt<IAdbRemoteDataSource>();
  final String serial;
  final bool isFloatingView;

  late final String sessionId;

  /// [ScrcpyController] chính cho thiết bị này.
  /// Được khởi tạo lazy khi start mirroring.
  plugin.ScrcpyController? _controller;
  plugin.ScrcpyController? get controller => _controller;

  StreamSubscription<plugin.ScrcpyState>? _stateSub;
  StreamSubscription<Size>? _frameSub;
  int _retryCount = 0;

  @observable
  DeviceShellResult? deviceShellResult;

  /// True khi người dùng đang ở tab Devices.
  @computed
  bool get isOnDevicesTab =>
      _dashboardStore.selectedIndex == DashboardTabs.devices;

  ReactionDisposer? _floatingDisposer;

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
    deviceShell.results.listen((result) {
      deviceShellResult = result;
    });
  }

  void dispose() {
    setVisibility(serial, false, isFloating: isFloatingView);
    _floatingDisposer?.call();
    stopMirroring();
    deviceShell.dispose();
    _stateSub?.cancel();
    _frameSub?.cancel();
  }

  // ═══════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  @computed
  MirrorSession? get session => sessionManagerStore.activeSessions[sessionId];

  late final DeviceShell _deviceShell = DeviceShell();
  DeviceShell get deviceShell => _deviceShell;

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
      !isFloatingView && sessionManagerStore.floatingSerial == serial;

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
      final bool wasVisible = _isVisible;
      _isVisible = isVisible || isFloating;

      if (wasVisible != _isVisible && _controller != null) {
        if (_isVisible) {
          if (_controller!.currentState == plugin.ScrcpyState.connected) {
            _controller!.resume();
          }
        } else {
          if (_controller!.currentState == plugin.ScrcpyState.connected && !_controller!.isPaused) {
            _controller!.pause();
          }
        }
      }

      // [Auto-Reconnect] Nếu trở nên hiển thị và trước đó bị mất kết nối, tự động kết nối lại
      if (!wasVisible && _isVisible && hasLostConnection && !isLoading && !isConnecting) {
        logger.i('[PhoneViewStore] Widget became visible, triggering auto-reconnect for $serial');
        startMirroring();
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MIRRORING LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  @action
  Future<MirrorSession?> startMirroring([plugin.ScrcpyOptions? options]) async {
    if (isConnecting || isLoading) return session;

    // [Optimization] Nếu đã có session đang hoạt động cho ID này, tái sử dụng nó
    if (session != null) {
      logger.i('[PhoneViewStore] Reusing existing session for $sessionId');
      runInAction(() {
        isLoading = false;
        isConnecting = false;
        error = null;
        hasLostConnection = false;
      });
      return session;
    }

    runInAction(() {
      isLoading = true;
      error = null;
      hasLostConnection = false;
      isConnecting = true;
    });

    if (!isFloatingView) {
      final previousQueue = _globalStartQueue;
      final completer = Completer<void>();
      _globalStartQueue = completer.future;

      // Chờ thiết bị trước đó
      await previousQueue;

      // Cho phép thiết bị tiếp theo bắt đầu sau 150ms
      Future.delayed(const Duration(milliseconds: 200), () {
        completer.complete();
      });
    }

    try {


      if (session != null) return session!;

      // Lấy hoặc tạo controller cho serial này theo sessionId
      _controller = _controllerService.getOrCreate(sessionId);

      // Hủy subscription cũ nếu có
      await _stateSub?.cancel();
      await _frameSub?.cancel();

      // Lắng nghe thay đổi trạng thái từ plugin
      _stateSub = _controller!.onStateChanged.listen(_handleStateChange);

      // Lắng nghe kích thước video khi frame đầu tiên đến và khi thiết bị xoay màn hình
      final sizeCompleter = Completer<Size>();
      _frameSub = _controller!.onVideoFrame.listen((size) {
        if (!sizeCompleter.isCompleted) sizeCompleter.complete(size);
        final current = sessionManagerStore.activeSessions[sessionId];
        if (current == null ||
            current.width != size.width.toInt() ||
            current.height != size.height.toInt()) {
          runInAction(() {
            sessionManagerStore.activeSessions[sessionId] = MirrorSession(
              width: size.width.toInt(),
              height: size.height.toInt(),
              deviceShell: _deviceShell,
            );
          });
        }
      });

      final pluginOptions = isFloatingView
          ? PerformanceProfiles.forFloating(serial)
          : (options ?? PerformanceProfiles.forGrid(serial));

      // Gán một port tĩnh (từ pool) để chắc chắn tiến trình này không tranh chấp port
      final basePort = _controllerService.getPortForSession(sessionId);
      pluginOptions.portRangeFirst = basePort;
      pluginOptions.portRangeLast = basePort + 19; // Dành 20 port để scrcpy tự động retry nếu Address already in use

      await _controller!.start(pluginOptions);

      final existingSize = _controller!.videoSize;
      final Size finalSize;
      if (existingSize != null) {
        finalSize = existingSize;
      } else {
        // Đợi tối đa 10s để lấy kích thước video
        finalSize = await sizeCompleter.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () => const Size(1080, 1920),
        );
      }

      final mirrorSession = MirrorSession(
        width: finalSize.width.toInt(),
        height: finalSize.height.toInt(),
        deviceShell: _deviceShell,
      );

      runInAction(() {
        sessionManagerStore.activeSessions[sessionId] = mirrorSession;
        isLoading = false;
        _retryCount = 0;
      });

      return mirrorSession;
    } catch (e, stackTrace) {
      logger.e('[PhoneViewStore] ERROR during mirroring setup', error: e, stackTrace: stackTrace);
      runInAction(() {
        error = 'Mirror failed: $e';
        isLoading = false;
      });
      rethrow;
    } finally {
      runInAction(() => isConnecting = false);
    }
  }

  void _handleStateChange(plugin.ScrcpyState state) {
    logger.i('[PhoneViewStore] ScrcpyState changed: $state for $serial');
    switch (state) {
      case plugin.ScrcpyState.connected:
        runInAction(() {
          isConnecting = false;
          hasLostConnection = false;
          error = null;
        });
      case plugin.ScrcpyState.disconnected:
        runInAction(() {
          sessionManagerStore.activeSessions.remove(sessionId);
          hasLostConnection = true;
        });
        // Auto-retry với exponential back-off
        // Cleanup controller cũ trước khi retry để tránh 2 session song song
        if (_retryCount < 3 && (_isVisible || isFloatingView)) {
          final delaySeconds = [1, 2, 5][_retryCount];
          _retryCount++;
          Timer(Duration(seconds: delaySeconds), () {
            if (_isVisible || isFloatingView) {
              // Giải phóng controller cũ trước — đảm bảo không còn zombie session
              _controllerService.release(sessionId);
              _controller = null;
              startMirroring();
            }
          });
        }
      case plugin.ScrcpyState.error:
        runInAction(() {
          error = 'Scrcpy connection error';
          isLoading = false;
          isConnecting = false;
        });
      case plugin.ScrcpyState.connecting:
        runInAction(() => isConnecting = true);
    }
  }

  @action
  Future<void> stopMirroring() async {
    _controllerService.release(sessionId);
    _controller = null;
    
    sessionManagerStore.activeSessions.remove(sessionId);

    runInAction(() {
      isLoading = false;
      isConnecting = false;
      error = null;
    });
  }

  @action
  void setDecoderError(String serial, String error) {
    this.error = 'Decoder error: $error';
  }

  // ═══════════════════════════════════════════════════════════════
  // INPUT HANDLING
  // ═══════════════════════════════════════════════════════════════

  void handlePointerEvent(String serial, PointerEvent event, int action, int nativeWidth, int nativeHeight) {
    if (_controller == null) return;
    final nx = (event.localPosition.dx / nativeWidth).clamp(0.0, 1.0);
    final ny = (event.localPosition.dy / nativeHeight).clamp(0.0, 1.0);
    _controller!.sendTouch(action, 0, nx, ny, 1.0);
  }

  void sendTouch(String sessionId, int x, int y, int action, int width, int height, {int buttons = UIConstants.defaultTouchButtons}) {
    if (_controller == null || x < 0 || y < 0) return;
    final nx = x / width;
    final ny = y / height;
    _controller!.sendTouch(action, 0, nx.clamp(0.0, 1.0), ny.clamp(0.0, 1.0), 1.0);
  }

  void handleScrollEvent(String serial, PointerScrollEvent event, int nativeWidth, int nativeHeight) {
    if (_controller == null) return;
    const double sensitivity = 15.0;
    _scrollAccumulatorX -= event.scrollDelta.dx * sensitivity;
    _scrollAccumulatorY -= event.scrollDelta.dy * sensitivity;

    int hScroll = _scrollAccumulatorX.truncate();
    int vScroll = _scrollAccumulatorY.truncate();

    if (hScroll == 0 && vScroll == 0) return;

    _scrollAccumulatorX -= hScroll;
    _scrollAccumulatorY -= vScroll;

    final nx = (event.localPosition.dx / nativeWidth).clamp(0.0, 1.0);
    final ny = (event.localPosition.dy / nativeHeight).clamp(0.0, 1.0);
    _controller!.sendScroll(nx, ny, hScroll / 50.0, -vScroll / 50.0);
  }

  double _scrollAccumulatorX = 0;
  double _scrollAccumulatorY = 0;

  void sendScroll(String sessionId, int x, int y, int width, int height, int hScroll, int vScroll) {
    if (_controller == null || x < 0 || y < 0) return;
    _controller!.sendScroll(x / width, y / height, hScroll / 50.0, -vScroll / 50.0);
  }

  void handleKeyboardEvent(String serial, KeyEvent event) {
    if (_controller == null) return;
    int action = -1;
    int repeat = 0;

    if (event is KeyDownEvent) {
      action = 0;
    } else if (event is KeyRepeatEvent) {
      action = 0;
      repeat = 1;
    } else if (event is KeyUpEvent) {
      action = 1;
    }

    if (action == -1) return;

    // Chặn phím Window (Meta) và các tổ hợp của nó
    if (event.logicalKey == LogicalKeyboardKey.meta ||
        event.logicalKey == LogicalKeyboardKey.metaLeft ||
        event.logicalKey == LogicalKeyboardKey.metaRight ||
        HardwareKeyboard.instance.isMetaPressed) {
      return;
    }

    final isModified = HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed;
    if (isModified && action == 0 && repeat == 0 && event.logicalKey == LogicalKeyboardKey.keyV) {
      handlePaste(serial);
      return;
    }

    final androidCode = AndroidKeyCodes.getKeyCodeFromPhysical(event.physicalKey);
    if (androidCode != AndroidKeyCodes.kUnknown) {
      sendKey(serial, androidCode, action, repeat: repeat, metaState: _getAndroidMetaState());
    }
  }

  void sendKey(String serial, int keyCode, int action, {int repeat = 0, int metaState = 0}) {
    if (_controller == null || keyCode == 0) return;
    _controller!.sendKey(keyCode, action, repeat, metaState);
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
    if (!sessionId.endsWith('_floating')) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) setClipboard(serial, text, paste: true);
  }

  void setClipboard(String serial, String text, {bool paste = false}) {
    _controller?.setClipboard(text, paste: paste);
  }

  void sendText(String serial, String text) {
    if (text.isEmpty) return;
    _controller?.injectText(text);
  }

  // ═══════════════════════════════════════════════════════════════
  // FILE OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  @action
  void setDragging(String serial, bool isDragging, {bool isApk = false}) {
    if (!isOnDevicesTab && !isFloatingView) return;
    isDraggingFile = isDragging;
    isDraggingApk = isDragging ? isApk : false;
  }

  @action
  DropOperation handleDropOver(DropOverEvent event) {
    if (!isFloatingView && !isOnDevicesTab) {
      return DropOperation.none;
    }
    if (isBlockedByFloating) return DropOperation.none;

    // Mặc định là dragging file bình thường
    setDragging(serial, true);

    // Kiểm tra xem có file APK nào đang được kéo không (Xử lý async)
    for (final item in event.session.items) {
      item.dataReader?.getSuggestedName().then((name) {
        if (name != null &&
            (name.toLowerCase().endsWith('.apk') ||
                name.toLowerCase().endsWith('.xapk'))) {
          runInAction(() => isDraggingApk = true);
        }
      });
    }

    return DropOperation.copy;
  }

  @action
  void handleDropLeave() {
    setDragging(serial, false);
  }

  @action
  Future<void> handlePerformDrop(PerformDropEvent event) async {
    setDragging(serial, false);

    // Guard: Bắt buộc phải được xác thực
    if (!getIt<AppAuthStore>().isAuthenticated) {
      logger.w('[PhoneViewStore] Unauthorized drop attempt blocked.');
      return;
    }

    // Guard 1: Không cho phép drop khi đang ở tab khác
    if (!isFloatingView && !isOnDevicesTab) return;

    // Guard 2: Nếu floating đang mở, chỉ floating view mới được nhận drop;
    if (isBlockedByFloating) return;

    final paths = <String>[];
    final completer = Completer<void>();
    var pending = 0;

    void tryComplete() {
      pending--;
      if (pending == 0) completer.complete();
    }

    for (final item in event.session.items) {
      final reader = item.dataReader;
      if (reader != null && reader.canProvide(Formats.fileUri)) {
        pending++;
        reader.getValue<Uri>(Formats.fileUri, (Uri? uri) {
          if (uri != null) paths.add(uri.toFilePath());
          tryComplete();
        });
      }
    }

    if (pending == 0) return; // không có file nào

    // Chờ tất cả callbacks
    await completer.future;

    if (paths.isNotEmpty) {
      uploadFiles(serial, paths);
    }
  }

  @action
  bool handleInternalDragWillAccept() {
    // Guard 1: Từ chối nếu không ở tab Devices
    if (!isFloatingView && !isOnDevicesTab) return false;

    // Guard 2: Từ chối nếu floating đang che grid
    if (isBlockedByFloating) return false;

    setDragging(serial, true);
    return true;
  }

  @action
  void handleInternalDragLeave() {
    setDragging(serial, false);
  }

  @action
  Future<void> handleInternalDragAccept(
    PosterData data,
    PosterDropHandler? onPosterDropped,
  ) async {
    setDragging(serial, false);

    // Guard: Bắt buộc phải được xác thực
    if (!getIt<AppAuthStore>().isAuthenticated) {
      logger.w('[PhoneViewStore] Unauthorized internal drop attempt blocked.');
      return;
    }

    if (onPosterDropped != null) {
      final file = await onPosterDropped(data);
      if (file != null) {
        await uploadFiles(serial, [file.path]);
      }
    }
  }

  @action
  Future<void> uploadFiles(String serial, List<String> paths) async {
    if (paths.isEmpty) return;

    final isVideo = paths.every((p) {
      final ext = p.toLowerCase().split('.').last;
      return const {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'ts', 'm4v', 'flv', 'wmv'}.contains(ext);
    });
    final isApk = paths.every((p) => p.toLowerCase().endsWith('.apk'));
    final isXapk = paths.every((p) => p.toLowerCase().endsWith('.xapk'));
    
    if (!isOnDevicesTab && !isVideo && !isApk && !isXapk) return;

    await _deviceTaskService.executeFileUploadTask(serial, paths);
  }

  @action
  void cancelActiveTask() {
    final task = activeTask;
    if (task != null) {
      if (task.type == DeviceTaskType.script || task.type == DeviceTaskType.command) {
        getIt<TerminalStore>().stopCommand(serial);
      } else {
        _deviceTaskService.cancelTask(serial);
      }
    } else {
      sessionManagerStore.clearDeviceTask(serial);
    }
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
