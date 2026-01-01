import '../../presentation/widgets/device/native_video_decoder/native_video_decoder_service.dart';

class MirrorSession {
  final String videoUrl;
  final int width;
  final int height;
  final NativeVideoDecoderService decoderService;

  MirrorSession({
    required this.videoUrl,
    required this.width,
    required this.height,
    required this.decoderService,
  });
}
