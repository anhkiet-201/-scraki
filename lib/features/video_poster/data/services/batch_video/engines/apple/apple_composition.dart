import 'package:scraki/features/video_poster/data/services/batch_video/engines/common/ffmpeg_composition.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/apple/apple_toolkit.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

/// Apple-specific composition engine using VideoToolbox hardware acceleration.
class AppleComposition extends BaseFfmpegComposition<AppleToolkit> {
  AppleComposition({required super.hardwareResolver, required super.toolkit});

  @override
  GpuInfo get gpuInfo =>
      hardwareResolver.gpuInfo ??
      (
        name: 'apple_videotoolbox',
        encoder: 'h264_videotoolbox',
        hwaccel: 'videotoolbox',
        scaleFilter: 'scale', // scale_vt sometimes has issues with some pixel formats
        outputFormat: null,
        hasZscale: false,
        hasCudaFilters: false,
        preferredPixFmt: 'nv12', // Typical for Apple HW
        maxConcurrentEncodes: 2,
      );
}
