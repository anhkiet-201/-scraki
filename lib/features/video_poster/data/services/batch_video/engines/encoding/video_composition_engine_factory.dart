import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'implementations/composition/amf_composition_engine.dart';
import 'implementations/composition/cpu_composition_engine.dart';
import 'implementations/composition/nvidia_composition_engine.dart';
import 'implementations/composition/qsv_composition_engine.dart';
import 'implementations/composition/videotoolbox_composition_engine.dart';
import 'video_composition_engine.dart';

class VideoCompositionEngineFactory {
  static VideoCompositionEngine getEngine(GpuInfo gpuInfo) {
    final encoder = gpuInfo.encoder;
    
    if (encoder == 'h264_nvenc') {
      return NvidiaCompositionEngine();
    } else if (encoder == 'h264_qsv') {
      return QsvCompositionEngine();
    } else if (encoder == 'h264_amf') {
      return AmfCompositionEngine();
    } else if (encoder == 'h264_videotoolbox') {
      return VideoToolboxCompositionEngine();
    }
    
    return CpuCompositionEngine();
  }
}
