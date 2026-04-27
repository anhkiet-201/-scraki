import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

import 'implementations/cpu_video_engine.dart';
import 'implementations/nvidia_video_engine.dart';
import 'implementations/videotoolbox_video_engine.dart';
import 'video_encoding_engine.dart';

class VideoEncodingEngineFactory {
  static VideoEncodingEngine getEngine(GpuInfo gpuInfo) {
    final encoder = gpuInfo.encoder;
    
    if (encoder == 'h264_nvenc') {
      return NvidiaVideoEngine();
    } else if (encoder == 'h264_videotoolbox') {
      return VideoToolboxVideoEngine();
    } else if (encoder == 'libx264') {
      return CpuVideoEngine();
    }
    
    // Default fallback to CPU
    return CpuVideoEngine();
  }
}
