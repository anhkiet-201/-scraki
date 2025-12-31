import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/core/utils/android_key_codes.dart';
import 'package:scraki/domain/entities/mirror_session.dart';
import 'package:scraki/presentation/stores/phone_view_store.dart';
import 'package:scraki/core/utils/logger.dart';
import 'native_video_decoder.dart';

/// A widget that displays a mirroring view of a phone screen and handles input events.
class PhoneView extends StatefulWidget {
  /// The ADB serial of the device to mirror.
  final String serial;

  /// How to fit the video stream within the layout.
  final BoxFit fit;

  /// Whether this view is specifically for a floating window.
  final bool isFloating;

  const PhoneView({
    super.key,
    required this.serial,
    this.fit = BoxFit.contain,
    this.isFloating = false,
  });

  @override
  State<PhoneView> createState() => _PhoneViewState();
}

class _PhoneViewState extends State<PhoneView> {
  String? _streamUrl;
  int _nativeWidth = 1080;
  int _nativeHeight = 2336;
  bool _isLoading = true;
  String? _errorMessage;
  final FocusNode _focusNode = FocusNode();

  // Double tap detection
  DateTime? _lastTapTime;
  static const _doubleTapTimeout = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _startMirroring();
  }

  @override
  void dispose() {
    final store = getIt<PhoneViewStore>();
    store.setVisibility(widget.serial, false);

    // Only stop mirroring if:
    // 1. This is NOT a floating view (don't kill mirroring from floating overlay)
    // 2. AND the serial is not currently floating (keep session alive for floating window)
    if (!widget.isFloating && store.floatingSerial != widget.serial) {
      store.stopMirroring(widget.serial);
    }
    super.dispose();
  }

  Future<void> _startMirroring() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      logger.i('[PhoneView] Starting mirroring for ${widget.serial}...');
      final store = getIt<PhoneViewStore>();
      final session = await store.startMirroring(widget.serial);
      logger.i(
        '[PhoneView] Received session URL: ${session.videoUrl} (${session.width}x${session.height})',
      );

      if (!mounted) return;

      setState(() {
        _streamUrl = session.videoUrl;
        _nativeWidth = session.width;
        _nativeHeight = session.height;
        _isLoading = false;
      });
    } catch (e) {
      logger.e('[PhoneView] ERROR starting mirroring', error: e);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _onDecoderError(String error) {
    logger.e('[PhoneView] Decoder error: $error');
    if (!mounted) return;
    setState(() {
      _errorMessage = 'Decoder error: $error';
    });
  }

  void _handleDoubleTap() {
    logger.i(
      '[PhoneView] Double tap detected! Toggling floating window for ${widget.serial}',
    );
    getIt<PhoneViewStore>().toggleFloating(widget.serial);
  }

  void _handlePointer(PointerEvent event, int action) {
    // Request focus on tap to enable keyboard input
    if (action == 0 && !_focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
    }
    _onInput(event, action, _nativeWidth, _nativeHeight);
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _onScroll(event, _nativeWidth, _nativeHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = getIt<PhoneViewStore>();

    return Observer(
      builder: (_) {
        final session = store.activeSessions[widget.serial];

        // Accessing these ensures the Observer is always active
        final isFloating = store.floatingSerial == widget.serial;

        return VisibilityDetector(
          key: Key('visibility_${widget.serial}'),
          onVisibilityChanged: (info) {
            final isVisible =
                info.visibleFraction > 0.05; // visible if more than 5%
            store.setVisibility(widget.serial, isVisible);
          },
          child: _buildContent(context, store, session, isFloating),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PhoneViewStore store,
    MirrorSession? session,
    bool isFloating,
  ) {
    // If this is the grid view AND the device is currently floating, show a placeholder
    if (!widget.isFloating && isFloating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.picture_in_picture,
              size: 48,
              color: Colors.white24,
            ),
            const SizedBox(height: 8),
            const Text(
              'Floating Mode',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            TextButton(
              onPressed: _handleDoubleTap,
              child: const Text('Bring Back'),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 32, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              'Mirroring Failed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startMirroring,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading && session == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to device...'),
          ],
        ),
      );
    }

    if (session == null && _errorMessage == null) {
      return const Center(child: Text('Initializing session...'));
    }

    final displayUrl = session?.videoUrl ?? _streamUrl;
    if (displayUrl == null && _errorMessage == null) {
      return const Center(child: Text('Waiting for stream URL...'));
    }

    return FittedBox(
      fit: widget.fit,
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          final action = (event is KeyDownEvent)
              ? 0
              : (event is KeyUpEvent)
              ? 1
              : -1;
          if (action != -1) {
            _onKey(event.logicalKey.keyId, action);
          }
        },
        child: Listener(
          onPointerDown: (e) => _handlePointer(e, 0),
          onPointerUp: (e) => _handlePointer(e, 1),
          onPointerMove: (e) => _handlePointer(e, 2),
          onPointerSignal: _handleScroll,
          child: SizedBox(
            width: (session?.width ?? _nativeWidth).toDouble(),
            height: (session?.height ?? _nativeHeight).toDouble(),
            child: NativeVideoDecoder(
              key: Key('decoder_${widget.serial}'),
              streamUrl: displayUrl!,
              nativeWidth: session?.width ?? _nativeWidth,
              nativeHeight: session?.height ?? _nativeHeight,
              service: session!.decoderService,
              fit: widget.fit,
              onError: _onDecoderError,
            ),
          ),
        ),
      ),
    );
  }

  void _onKey(int keyId, int action) {
    final key = LogicalKeyboardKey.findKeyByKeyId(keyId);
    if (key != null) {
      final androidCode = AndroidKeyCodes.getKeyCode(key);
      if (androidCode != AndroidKeyCodes.kUnknown) {
        getIt<PhoneViewStore>().sendKey(widget.serial, androidCode, action);
      }
    }
  }

  void _onScroll(PointerScrollEvent event, int width, int height) {
    getIt<PhoneViewStore>().handleScrollEvent(
      widget.serial,
      event,
      width,
      height,
    );
  }

  void _onInput(PointerEvent event, int action, int width, int height) {
    // Double tap detection
    if (action == 0) {
      // PointerDown
      final now = DateTime.now();
      if (_lastTapTime != null &&
          now.difference(_lastTapTime!) < _doubleTapTimeout) {
        _handleDoubleTap();
        _lastTapTime = null; // Reset
      } else {
        _lastTapTime = now;
      }
    }

    getIt<PhoneViewStore>().handlePointerEvent(
      widget.serial,
      event,
      action,
      width,
      height,
    );
  }
}
