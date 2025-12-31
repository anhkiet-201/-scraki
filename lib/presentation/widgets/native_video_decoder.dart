import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Callback for input events (action, x, y, viewWidth, viewHeight)
  /// Action: 0=Down, 1=Up, 2=Move
  final void Function(int action, int x, int y, int width, int height)? onInput;
  
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
      print('[NativeVideoDecoder] Starting decoder for ${widget.streamUrl}');

      final dynamic result = await platform.invokeMethod('startDecoding', {
        'url': widget.streamUrl,
      });

      if (!mounted) return;

      if (result is int) {
        print('[NativeVideoDecoder] Received texture ID: $result');
        setState(() {
          _textureId = result;
          _isInitializing = false;
        });
      } else {
        throw Exception('Invalid response from native decoder');
      }
    } catch (e) {
      print('[NativeVideoDecoder] Failed to start decoding: $e');
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
      print('[NativeVideoDecoder] Decoder stopped');
    } catch (e) {
      print('[NativeVideoDecoder] Error stopping decoder: $e');
    }
  }

  void _handlePointer(PointerEvent event, int action) {
    if (widget.onInput == null) return;
    
    // Request focus on tap to enable keyboard input
    if (action == 0 && !_focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
    }
    
    // Coordinates are local to the SizedBox due to Listener inside FittedBox
    final x = event.localPosition.dx.toInt().clamp(0, widget.nativeWidth);
    final y = event.localPosition.dy.toInt().clamp(0, widget.nativeHeight);
    
    widget.onInput!(action, x, y, widget.nativeWidth, widget.nativeHeight);
  }
  
  void _handleKey(KeyEvent event) {
    if (widget.onKey == null) return;
    if (event is KeyRepeatEvent) return; // Ignore repeats for now or handle them? Scrcpy repeats sent as Down
    
    // Map LogicalKey to Android KeyCode (User needs to implement mapping logic externally or pass raw?)
    // Actually best to pass LogicalKeyboardKey and map outside, but for now we pass generic int if we mapped here.
    // Let's pass the raw Flutter Key ID or map it outside?
    // The prompt implied passing (keyCode, action).
    // Let's assume the parent widget handles mapping? 
    // No, NativeVideoDecoder is low level UI.
    // But we need to pass the raw event or a mapped code.
    // Let's pass the raw LogicalKeyboardKey keyId and let parent map it.
    // Wait, the callback signature is (int keyCode, int action).
    // I will assume the parent does the mapping if I pass the Flutter ID?
    // Or I should map it here using the util class I just created?
    // I cannot import 'android_key_codes.dart' easily without adding import.
    // Let's modify the file imports first.
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
               // 0=Down, 1=Up
               final action = (event is KeyDownEvent) ? 0 : (event is KeyUpEvent) ? 1 : -1;
               if (action != -1) {
                  // Pass the Flutter Logical Key ID, parent will map it
                  widget.onKey!(event.logicalKey.keyId, action);
               }
             }
        },
        child: Listener(
          onPointerDown: (e) => _handlePointer(e, 0), // Action Down
          onPointerUp: (e) => _handlePointer(e, 1),   // Action Up
          onPointerMove: (e) => _handlePointer(e, 2), // Action Move
          child: SizedBox(
            width: widget.nativeWidth.toDouble(), 
            height: widget.nativeHeight.toDouble(),
            child: Texture(
              textureId: _textureId!,
              filterQuality: FilterQuality.low, // Low latency, no smoothing
            ),
          ),
        ),
      ),
    );
  }
}
