import 'package:scraki/features/video_poster/data/services/batch_video/core/engine/video_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/apple/vt_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/cpu/cpu_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/nvidia/nvidia_batch_engine.dart';

class VideoBatchEngineFactory {
  static VideoBatchEngine createEngine(VideoHardwareCapabilityResolver resolver) {
    final gpuInfo = resolver.gpuInfo!;
    final encoder = gpuInfo.encoder;
    
    if (encoder == 'h264_nvenc') {
      return NvidiaBatchEngine(hardwareResolver: resolver);
    } else if (encoder == 'h264_videotoolbox') {
      return VtBatchEngine(hardwareResolver: resolver);
    }
    
    // Default to CPU
    return CpuBatchEngine(hardwareResolver: resolver);
  }
}
