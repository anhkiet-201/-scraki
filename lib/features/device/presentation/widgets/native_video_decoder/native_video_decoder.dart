import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/device/presentation/widgets/native_video_decoder/store/native_video_decoder_store.dart';
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
  late final NativeVideoDecoderStore _store;

  @override
  void initState() {
    _store = NativeVideoDecoderStore(
      streamUrl: widget.streamUrl,
      nativeWidth: widget.nativeWidth,
      nativeHeight: widget.nativeHeight,
      service: widget.service,
      isVisible: widget.isVisible,
      onError: widget.onError,
    );
    super.initState();
  }

  @override
  void didUpdateWidget(NativeVideoDecoder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle visibility changes
    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        _store.acquireTexture();
      } else {
        _store.releaseTexture();
      }
    }

    // Handle URL changes
    if (oldWidget.streamUrl != widget.streamUrl) {
      if (_store.textureId != null) {
        _store.releaseTexture();
      }
      if (widget.isVisible) {
        _store.acquireTexture();
      }
    }
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show placeholder when not visible outside Observer to avoid MobX tracking errors
    if (!widget.isVisible) {
      return Container(color: Colors.black);
    }

    return Observer(
      builder: (_) {
        if (_store.isInitializing) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_store.textureId == null) {
          return const Center(
            child: Icon(Icons.videocam_off, color: Colors.white24, size: 48),
          );
        }

        return Texture(textureId: _store.textureId!);
      },
    );
  }
}
