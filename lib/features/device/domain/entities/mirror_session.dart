
import 'package:scraki/features/device/domain/services/device_shell.dart';
import 'package:scraki/features/device/domain/services/i_video_decoder_service.dart';

class MirrorSession {
  final String videoUrl;
  final int width;
  final int height;
  final int port;
  final String scid;
  final IVideoDecoderService decoderService;
  final DeviceShell deviceShell;

  MirrorSession({
    required this.videoUrl,
    required this.width,
    required this.height,
    required this.port,
    required this.scid,
    required this.decoderService,
    required this.deviceShell,
  });

  MirrorSession copyWith({
    String? videoUrl,
    int? width,
    int? height,
    int? port,
    String? scid,
    IVideoDecoderService? decoderService,
    DeviceShell? deviceShell,
  }) {
    return MirrorSession(
      videoUrl: videoUrl ?? this.videoUrl,
      width: width ?? this.width,
      height: height ?? this.height,
      port: port ?? this.port,
      scid: scid ?? this.scid,
      decoderService: decoderService ?? this.decoderService,
      deviceShell: deviceShell ?? this.deviceShell,
    );
  }
}
