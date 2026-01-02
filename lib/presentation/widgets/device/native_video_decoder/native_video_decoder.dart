import 'package:flutter/material.dart';
import '../../../../core/utils/logger.dart';
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

  /// Whether the video is currently visible in the viewport.
  /// When false, texture will be released to save GPU memory.
  final bool isVisible;

  const NativeVideoDecoder({
    super.key,
    required this.streamUrl,
    required this.nativeWidth,
    required this.nativeHeight,
    required this.service,
    this.fit = BoxFit.contain,
    this.onError,
    this.isVisible = true,
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
    if (widget.isVisible) {
      _acquireTexture();
    }
  }

  @override
  void didUpdateWidget(NativeVideoDecoder oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle visibility changes
    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        _acquireTexture();
      } else {
        _releaseTexture();
      }
    }

    // Handle URL changes
    if (oldWidget.streamUrl != widget.streamUrl) {
      if (_textureId != null) {
        _service.stop(oldWidget.streamUrl);
      }
      if (widget.isVisible) {
        _acquireTexture();
      }
    }
  }

  @override
  void dispose() {
    if (_textureId != null) {
      _releaseTexture();
    }
    super.dispose();
  }

  Future<void> _acquireTexture() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      logger.i(
        '[NativeVideoDecoder] Acquiring texture for ${widget.streamUrl}',
      );
      final textureId = await _service.start(widget.streamUrl);

      if (!mounted) return;

      setState(() {
        _textureId = textureId;
        _isInitializing = false;
      });
      logger.i('[NativeVideoDecoder] Received texture ID: $textureId');
    } catch (e) {
      logger.e('[NativeVideoDecoder] Error acquiring texture', error: e);
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _releaseTexture() {
    if (_textureId != null) {
      logger.i(
        '[NativeVideoDecoder] Releasing texture for ${widget.streamUrl}',
      );
      _service.stop(widget.streamUrl);
      if (mounted) {
        setState(() {
          _textureId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show placeholder when not visible
    if (!widget.isVisible) {
      return Container(color: Colors.black);
    }

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
