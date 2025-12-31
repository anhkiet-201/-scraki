import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/logger.dart';

/// Widget that renders video from native FFmpeg decoder via Flutter Texture.
/// This provides ultra-low latency video playback without media player buffering.
class NativeVideoDecoder extends StatefulWidget {
  /// URL of the video stream (format: tcp://127.0.0.1:PORT)
  final String streamUrl;

  /// How to inscribe the video into the space allocated during layout
  final BoxFit fit;

  /// Native resolution of the video
  final int nativeWidth;
  final int nativeHeight;

  /// Callback when decoder encounters an error
  final void Function(String error)? onError;

  /// Callback for input events (action, x, y, viewWidth, viewHeight, buttons)
  /// Action: 0=Down, 1=Up, 2=Move
  final void Function(
    int action,
    int x,
    int y,
    int width,
    int height,
    int buttons,
  )?
  onInput;

  /// Callback for scroll events (x, y, w, h, hScroll, vScroll)
  final void Function(
    int x,
    int y,
    int width,
    int height,
    int hScroll,
    int vScroll,
  )?
  onScroll;

  /// Callback for key events (keyCode, action)
  /// Action: 0=Down, 1=Up
  final void Function(int keyCode, int action)? onKey;

  const NativeVideoDecoder({
    super.key,
    required this.streamUrl,
    required this.nativeWidth,
    required this.nativeHeight,
    this.fit = BoxFit.contain,
    this.onError,
    this.onInput,
    this.onScroll,
    this.onKey,
  });

  @override
  State<NativeVideoDecoder> createState() => _NativeVideoDecoderState();
}

class _NativeVideoDecoderState extends State<NativeVideoDecoder> {
  static const platform = MethodChannel('scraki/video_decoder');

  int? _textureId;
  bool _isInitializing = true;
  String? _errorMessage;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startDecoding();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _stopDecoding();
    super.dispose();
  }

  Future<void> _startDecoding() async {
    try {
      logger.i('[NativeVideoDecoder] Starting decoder for ${widget.streamUrl}');

      final dynamic result = await platform.invokeMethod('startDecoding', {
        'url': widget.streamUrl,
      });

      if (!mounted) return;

      if (result is int) {
        logger.i('[NativeVideoDecoder] Received texture ID: $result');
        setState(() {
          _textureId = result;
          _isInitializing = false;
        });
      } else {
        throw Exception('Invalid response from native decoder');
      }
    } catch (e) {
      logger.e('[NativeVideoDecoder] Failed to start decoding', error: e);
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isInitializing = false;
      });

      widget.onError?.call(e.toString());
    }
  }

  Future<void> _stopDecoding() async {
    if (_textureId == null) return;

    try {
      await platform.invokeMethod('stopDecoding', {'textureId': _textureId});
      logger.i('[NativeVideoDecoder] Decoder stopped');
    } catch (e) {
      logger.e('[NativeVideoDecoder] Error stopping decoder', error: e);
    }
  }

  void _handlePointer(PointerEvent event, int action) {
    if (widget.onInput == null) return;

    // Request focus on tap to enable keyboard input
    if (action == 0 && !_focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
    }

    final x = event.localPosition.dx.toInt().clamp(0, widget.nativeWidth);
    final y = event.localPosition.dy.toInt().clamp(0, widget.nativeHeight);
    int buttons = event.buttons;

    widget.onInput!(
      action,
      x,
      y,
      widget.nativeWidth,
      widget.nativeHeight,
      buttons,
    );
  }

  void _handleScroll(PointerSignalEvent event) {
    if (widget.onScroll == null) return;
    if (event is PointerScrollEvent) {
      final x = event.localPosition.dx.toInt().clamp(0, widget.nativeWidth);
      final y = event.localPosition.dy.toInt().clamp(0, widget.nativeHeight);

      int hScroll = -(event.scrollDelta.dx / 20).round();
      int vScroll = -(event.scrollDelta.dy / 20).round();

      if (hScroll == 0 && vScroll == 0) return;

      widget.onScroll!(
        x,
        y,
        widget.nativeWidth,
        widget.nativeHeight,
        hScroll,
        vScroll,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Decoder Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isInitializing || _textureId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing decoder...'),
          ],
        ),
      );
    }

    return FittedBox(
      fit: widget.fit,
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (widget.onKey != null) {
            final action = (event is KeyDownEvent)
                ? 0
                : (event is KeyUpEvent)
                ? 1
                : -1;
            if (action != -1) {
              widget.onKey!(event.logicalKey.keyId, action);
            }
          }
        },
        child: Listener(
          onPointerDown: (e) => _handlePointer(e, 0),
          onPointerUp: (e) => _handlePointer(e, 1),
          onPointerMove: (e) => _handlePointer(e, 2),
          onPointerSignal: _handleScroll,
          child: SizedBox(
            width: widget.nativeWidth.toDouble(),
            height: widget.nativeHeight.toDouble(),
            child: Texture(
              textureId: _textureId!,
              filterQuality: FilterQuality.low,
            ),
          ),
        ),
      ),
    );
  }
}
