import 'package:mobx/mobx.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/presentation/widgets/native_video_decoder/native_video_decoder_service.dart';

part 'native_video_decoder_store.g.dart';

// ignore: library_private_types_in_public_api
class NativeVideoDecoderStore = _NativeVideoDecoderStore
    with _$NativeVideoDecoderStore;

abstract class _NativeVideoDecoderStore with Store {
  /// The URL of the video stream (e.g., tcp://127.0.0.1:port)
  final String streamUrl;

  /// The native width of the video stream.
  final int nativeWidth;

  /// The native height of the video stream.
  final int nativeHeight;

  /// Callback when decoder encounters an error
  final void Function(String error)? onError;

  /// The decoder service to use (shared between grid and floating)
  final NativeVideoDecoderService service;

  /// Whether the video is currently visible in the viewport.
  /// When false, texture will be released to save GPU memory.
  final bool isVisible;
  _NativeVideoDecoderStore({
    required this.streamUrl,
    required this.nativeWidth,
    required this.nativeHeight,
    required this.service,
    required this.isVisible,
    required this.onError,
  }) {
    if (isVisible) {
      acquireTexture();
    }
  }

  void dispose() {
    releaseTexture();
  }

  @readonly
  int? _textureId;

  @readonly
  bool _isInitializing = true;

  @action
  Future<void> acquireTexture() async {
    _isInitializing = true;
    try {
      logger.i('[NativeVideoDecoder] Acquiring texture for $streamUrl');
      _textureId = await service.start(streamUrl);
      _isInitializing = false;
      logger.i('[NativeVideoDecoder] Received texture ID: $_textureId');
    } catch (e) {
      logger.e('[NativeVideoDecoder] Error acquiring texture', error: e);
      _isInitializing = false;
    }
  }

  @action
  void releaseTexture() {
    if (_textureId != null) {
      logger.i('[NativeVideoDecoder] Releasing texture for $streamUrl');
      service.stop(streamUrl);
      _textureId = null;
    }
  }
}
