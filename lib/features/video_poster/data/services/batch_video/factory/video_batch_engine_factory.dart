import 'package:scraki/features/video_poster/data/services/batch_video/core/engine/video_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/apple/apple_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/cpu/cpu_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/nvidia/nvidia_batch_engine.dart';

import 'package:scraki/features/video_poster/data/services/batch_video/engines/metadata/video_metadata_analyzer.dart';

/// Factory responsible for instantiating the appropriate [VideoBatchEngine] 
/// based on detected hardware capabilities.
class VideoBatchEngineFactory {
  /// Creates a [VideoBatchEngine] tailored to the user's hardware.
  /// 
  /// Detects NVIDIA (NVENC), Apple (VideoToolbox), or falls back to CPU (libx264).
  static VideoBatchEngine createEngine(VideoHardwareCapabilityResolver resolver, VideoMetadataAnalyzer metadataAnalyzer) {
    final gpuInfo = resolver.gpuInfo;
    final encoder = gpuInfo?.encoder;
    
    if (encoder == 'h264_nvenc') {
      return NvidiaBatchEngine(hardwareResolver: resolver, metadataAnalyzer: metadataAnalyzer);
    } else if (encoder == 'h264_videotoolbox') {
      return AppleBatchEngine(hardwareResolver: resolver, metadataAnalyzer: metadataAnalyzer);
    }
    
    // Default to CPU
    return CpuBatchEngine(hardwareResolver: resolver, metadataAnalyzer: metadataAnalyzer);
  }
}

