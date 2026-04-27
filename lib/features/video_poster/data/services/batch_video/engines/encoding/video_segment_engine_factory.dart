import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'implementations/segment/amf_segment_engine.dart';
import 'implementations/segment/cpu_segment_engine.dart';
import 'implementations/segment/nvidia_segment_engine.dart';
import 'implementations/segment/qsv_segment_engine.dart';
import 'implementations/segment/videotoolbox_segment_engine.dart';
import 'video_segment_engine.dart';

class VideoSegmentEngineFactory {
  static VideoSegmentEngine getEngine(GpuInfo gpuInfo) {
    final encoder = gpuInfo.encoder;
    
    if (encoder == 'h264_nvenc') {
      return NvidiaSegmentEngine();
    } else if (encoder == 'h264_qsv') {
      return QsvSegmentEngine();
    } else if (encoder == 'h264_amf') {
      return AmfSegmentEngine();
    } else if (encoder == 'h264_videotoolbox') {
      return VideoToolboxSegmentEngine();
    }
    
    return CpuSegmentEngine();
  }
}
