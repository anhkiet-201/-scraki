import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget that renders video from native FFmpeg decoder via Flutter Texture.
/// This provides ultra-low latency video playback without media player buffering.
class NativeVideoDecoder extends StatefulWidget {
  /// URL of the video stream (format: tcp://127.0.0.1:PORT)
  final String streamUrl;

  /// How to inscribe the video into the space allocated during layout
  final BoxFit fit;

  /// Callback when decoder encounters an error
  final void Function(String error)? onError;

  /// Callback for input events (action, x, y, viewWidth, viewHeight)
  /// Action: 0=Down, 1=Up, 2=Move
  final void Function(int action, int x, int y, int width, int height)? onInput;

  const NativeVideoDecoder({
    super.key,
    required this.streamUrl,
    this.fit = BoxFit.contain,
    this.onError,
    this.onInput,
  });

  @override
  State<NativeVideoDecoder> createState() => _NativeVideoDecoderState();
}

class _NativeVideoDecoderState extends State<NativeVideoDecoder> {
  static const platform = MethodChannel('scraki/video_decoder');

  int? _textureId;
  bool _isInitializing = true;
  String? _errorMessage;
  
  // Dimensions - ideally should be dynamic from decoder
  final int _videoWidth = 1080;
  final int _videoHeight = 2336;

  @override
  void initState() {
    super.initState();
    _startDecoding();
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
    
    // Coordinates are local to the SizedBox due to Listener inside FittedBox
    final x = event.localPosition.dx.toInt().clamp(0, _videoWidth);
    final y = event.localPosition.dy.toInt().clamp(0, _videoHeight);
    
    widget.onInput!(action, x, y, _videoWidth, _videoHeight);
  }

  @override
  void dispose() {
    _stopDecoding();
    super.dispose();
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
      child: Listener(
        onPointerDown: (e) => _handlePointer(e, 0), // Action Down
        onPointerUp: (e) => _handlePointer(e, 1),   // Action Up
        onPointerMove: (e) => _handlePointer(e, 2), // Action Move
        child: SizedBox(
          width: _videoWidth.toDouble(), 
          height: _videoHeight.toDouble(),
          child: Texture(
            textureId: _textureId!,
            filterQuality: FilterQuality.low, // Low latency, no smoothing
          ),
        ),
      ),
    );
  }
}
