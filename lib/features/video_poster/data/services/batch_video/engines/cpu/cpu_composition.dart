import 'package:scraki/features/video_poster/data/services/batch_video/engines/common/ffmpeg_composition.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/cpu/cpu_toolkit.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

/// CPU-based composition engine using libx264 for software encoding.
class CpuComposition extends BaseFfmpegComposition<CpuToolkit> {
  CpuComposition({required super.hardwareResolver, required super.toolkit});

  @override
  GpuInfo get gpuInfo =>
      hardwareResolver.gpuInfo ??
      (
        name: 'cpu',
        encoder: 'libx264',
        hwaccel: null,
        scaleFilter: 'scale',
        outputFormat: null,
        hasZscale: false,
        hasCudaFilters: false,
        preferredPixFmt: 'yuv420p',
        maxConcurrentEncodes: 1,
      );
}
