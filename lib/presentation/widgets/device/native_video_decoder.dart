import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';
import 'native_video_decoder_service.dart';

/// A widget that decodes and displays a native video stream using Texture.
class NativeVideoDecoder extends StatefulWidget {
  /// The URL of the video stream (e.g., tcp://127.0.0.1:port)
  final String streamUrl;

  /// The native width of the video stream.
  final int nativeWidth;

  /// The native height of the video stream.
  final int nativeHeight;

  /// How to fit the video within the available space.
  final BoxFit fit;

  /// Callback when decoder encounters an error
  final void Function(String error)? onError;

  /// The decoder service to use (shared between grid and floating)
  final NativeVideoDecoderService service;

  const NativeVideoDecoder({
    super.key,
    required this.streamUrl,
    required this.nativeWidth,
    required this.nativeHeight,
    required this.service,
    this.fit = BoxFit.contain,
    this.onError,
  });

  @override
  State<NativeVideoDecoder> createState() => _NativeVideoDecoderState();
}

class _NativeVideoDecoderState extends State<NativeVideoDecoder> {
  int? _textureId;
  bool _isInitializing = true;

  NativeVideoDecoderService get _service => widget.service;

  @override
  void initState() {
    super.initState();
    _initDecoder();
  }

  @override
  void didUpdateWidget(NativeVideoDecoder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _service.stop(oldWidget.streamUrl);
      _initDecoder();
    }
  }

  @override
  void dispose() {
    _service.stop(widget.streamUrl);
    super.dispose();
  }

  Future<void> _initDecoder() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      logger.i('[NativeVideoDecoder] Starting decoder for ${widget.streamUrl}');
      // Don't call stop() here, as it might kill a shared session!
      // _initDecoder is called when we need this texture.
      final textureId = await _service.start(widget.streamUrl);

      if (!mounted) return;

      setState(() {
        _textureId = textureId;
        _isInitializing = false;
      });
      logger.i('[NativeVideoDecoder] Received texture ID: $textureId');
    } catch (e) {
      logger.e('[NativeVideoDecoder] Error initializing decoder', error: e);
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_textureId == null) {
      return const Center(
        child: Icon(Icons.videocam_off, color: Colors.white24, size: 48),
      );
    }

    return Texture(textureId: _textureId!);
  }
}
