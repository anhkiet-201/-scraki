import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import '../../../core/di/injection.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/utils/android_key_codes.dart';
import '../../../core/utils/logger.dart';
import '../../../data/datasources/scrcpy_client.dart';
import '../../../data/services/scrcpy_service.dart';
import '../../../data/services/video_worker_manager.dart';
import '../../../data/utils/scrcpy_input_serializer.dart';
import '../../../domain/entities/scrcpy_options.dart';
import '../../../domain/entities/mirror_session.dart';
import '../widgets/device/native_video_decoder/native_video_decoder_service.dart';

part 'mirroring_store.g.dart';

@lazySingleton
// ignore: library_private_types_in_public_api
class MirroringStore = _MirroringStore with _$MirroringStore;

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
abstract class _MirroringStore with Store {
  final ScrcpyService _scrcpyService;
  final VideoWorkerManager _workerManager;

  _MirroringStore(this._scrcpyService, this._workerManager);

  // ═══════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  @observable
  ObservableMap<String, MirrorSession> activeSessions =
      ObservableMap<String, MirrorSession>();

  @observable
  ObservableSet<String> visibleGridSerials = ObservableSet<String>();

  @observable
  ObservableSet<String> visibleFloatingSerials = ObservableSet<String>();

  bool isDeviceVisible(String serial) =>
      visibleGridSerials.contains(serial) ||
      visibleFloatingSerials.contains(serial);

  // ═══════════════════════════════════════════════════════════════
  // UI STATES
  // ═══════════════════════════════════════════════════════════════

  @observable
  ObservableMap<String, bool> isLoadingMirroring =
      ObservableMap<String, bool>();

  @observable
  ObservableMap<String, String?> errorMessages =
      ObservableMap<String, String?>();

  @observable
  ObservableMap<String, bool> lostConnectionSerials =
      ObservableMap<String, bool>();

  @observable
  ObservableMap<String, bool> isConnecting = ObservableMap<String, bool>();

  // File operations
  @observable
  ObservableMap<String, bool> isPushingFile = ObservableMap<String, bool>();

  @observable
  ObservableMap<String, bool> isDraggingFile = ObservableMap<String, bool>();

  // Double-tap detection state
  @observable
  ObservableMap<String, DateTime> lastTapTimes =
      ObservableMap<String, DateTime>();

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
  // VISIBILITY MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  @action
  void setVisibility(String serial, bool isVisible, {bool isFloating = false}) {
    final wasVisible = isDeviceVisible(serial);
    if (isFloating) {
      if (isVisible) {
        visibleFloatingSerials.add(serial);
      } else {
        visibleFloatingSerials.remove(serial);
      }
    } else {
      if (isVisible) {
        visibleGridSerials.add(serial);
      } else {
        visibleGridSerials.remove(serial);
      }
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

  // ═══════════════════════════════════════════════════════════════
  // MIRRORING LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  @action
  Future<MirrorSession> startMirroring(
    String serial, [
    ScrcpyOptions? options,
  ]) async {
    runInAction(() {
      isLoadingMirroring[serial] = true;
      errorMessages.remove(serial);
      lostConnectionSerials.remove(serial);
      isConnecting[serial] = true;
    });

    try {
      // Check if device is connected
      final isOnline = await _scrcpyService.isDeviceConnected(serial);
      if (!isOnline) {
        throw 'Device $serial is not connected or unauthorized. Please check your cable/ADB status.';
      }

      // Return existing session if available
      if (activeSessions.containsKey(serial)) {
        logger.i(
          '[MirroringStore] Using existing mirroring session for $serial',
        );
        return activeSessions[serial]!;
      }

      logger.i('[MirroringStore] Starting new mirroring session for $serial');
      const scrcpyOptions = ScrcpyOptions();

      // Initialize worker and get ports
      final resolutionFuture = _workerManager.waitForEvent(
        serial,
        'resolution_ready',
      );

      final portsData = await _workerManager.startMirroring(
        serial,
        listener: (event) {
          if (event.type == 'connection_lost') {
            logger.w('[MirroringStore] Connection lost for $serial');
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

      // Setup Scrcpy Server
      await _scrcpyService.initServer(serial, scrcpyOptions, adbPort);

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
        decoderService: NativeVideoDecoderService(),
      );

      // Pre-warm decoder
      await mirrorSession.decoderService.start(url);

      runInAction(() {
        activeSessions[serial] = mirrorSession;
        isLoadingMirroring[serial] = false;
      });

      return mirrorSession;
    } catch (e, stackTrace) {
      logger.e(
        '[MirroringStore] ERROR during mirroring setup',
        error: e,
        stackTrace: stackTrace,
      );
      runInAction(() {
        errorMessages[serial] = 'Mirror failed: $e';
        isLoadingMirroring[serial] = false;
      });
      rethrow;
    } finally {
      runInAction(() => isConnecting[serial] = false);
    }
  }

  @action
  Future<void> stopMirroring(String serial) async {
    logger.i('[MirroringStore] Stopping mirroring for $serial');
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
      logger.w('[MirroringStore] Error cleaning up', error: e);
    }
  }

  @action
  void setDecoderError(String serial, String error) {
    errorMessages[serial] = 'Decoder error: $error';
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
      serial,
      x,
      y,
      action,
      nativeWidth,
      nativeHeight,
      buttons: buttons,
    );
  }

  void sendTouch(
    String serial,
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

    _workerManager.sendControl(serial, message.serialize());
  }

  // ═══════════════════════════════════════════════════════════════
  // INPUT HANDLING - Scroll Events
  // ═══════════════════════════════════════════════════════════════

  @action
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

  // ═══════════════════════════════════════════════════════════════
  // INPUT HANDLING - Keyboard Events
  // ═══════════════════════════════════════════════════════════════

  @action
  void handleKeyboardEvent(String serial, KeyEvent event) {
    final action = (event is KeyDownEvent)
        ? 0
        : (event is KeyUpEvent)
        ? 1
        : -1;

    if (action == -1) return;

    // Check for keyboard shortcuts
    final isModified =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    if (isModified && action == 0) {
      if (event.logicalKey == LogicalKeyboardKey.keyV) {
        handlePaste(serial);
        return;
      }
    }

    // Send regular key event
    final androidCode = AndroidKeyCodes.getKeyCode(event.logicalKey);
    if (androidCode != AndroidKeyCodes.kUnknown) {
      sendKey(serial, androidCode, action, metaState: _getAndroidMetaState());
    }
  }

  void sendKey(String serial, int keyCode, int action, {int metaState = 0}) {
    if (keyCode == 0) return;

    final message = KeyControlMessage(
      action: action,
      keyCode: keyCode,
      metaState: metaState,
    );

    _workerManager.sendControl(serial, message.serialize());
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
        '[MirroringStore] Pasting text to $serial: ${text.length} chars',
      );
      setClipboard(serial, text, paste: true);
    }
  }

  void setClipboard(String serial, String text, {bool paste = false}) {
    final message = SetClipboardControlMessage(text, paste: paste);
    _workerManager.sendControl(serial, message.serialize());
  }

  void sendText(String serial, String text) {
    if (text.isEmpty) return;
    final message = InjectTextControlMessage(text);
    _workerManager.sendControl(serial, message.serialize());
  }

  // ═══════════════════════════════════════════════════════════════
  // FILE OPERATIONS
  // ═══════════════════════════════════════════════════════════════

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
        '[MirroringStore] Successfully pushed ${paths.length} files to $serial',
      );
    } catch (e) {
      logger.e('[MirroringStore] Failed to push files to $serial', error: e);
      runInAction(() => errorMessages[serial] = 'Failed to push files: $e');
    } finally {
      runInAction(() => isPushingFile[serial] = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DOUBLE-TAP DETECTION
  // ═══════════════════════════════════════════════════════════════

  @action
  bool checkDoubleTap(String serial) {
    final now = DateTime.now();
    final lastTap = lastTapTimes[serial];

    if (lastTap != null &&
        now.difference(lastTap) < UIConstants.doubleTapTimeout) {
      // Double tap detected
      lastTapTimes.remove(serial);
      toggleFloating(serial);
      logger.i('[MirroringStore] Double tap detected for $serial');
      return true;
    } else {
      // First tap or timeout
      lastTapTimes[serial] = now;
      return false;
    }
  }
}
