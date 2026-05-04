import 'package:scraki/features/video_poster/data/services/batch_video/engines/common/ffmpeg_composition.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/nvidia/nvidia_toolkit.dart';

/// NVIDIA-specific composition engine using NVENC and CUDA filters.
class NvidiaComposition extends BaseFfmpegComposition<NvidiaToolkit> {
  NvidiaComposition({required super.hardwareResolver, required super.toolkit});

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