
import 'package:scraki/features/device/domain/services/i_video_decoder_service.dart';

class MirrorSession {
  final String videoUrl;
  final int width;
  final int height;
  final int port;
  final String scid;
  final IVideoDecoderService decoderService;

  MirrorSession({
    required this.videoUrl,
    required this.width,
    required this.height,
    required this.port,
    required this.scid,
    required this.decoderService,
  });
}
