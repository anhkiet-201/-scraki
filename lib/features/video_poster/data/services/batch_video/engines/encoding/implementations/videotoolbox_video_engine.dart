import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import '../video_encoding_engine.dart';

class VideoToolboxVideoEngine implements VideoEncodingEngine {
  @override
  String buildVideoFilter({
    required bool isHdr,
    required bool hflip,
    required int width,
    required int height,
    required GpuInfo gpuInfo,
  }) {
    final hwScale = gpuInfo.scaleFilter ?? 'scale';
    final resolution = '$width:$height';

    String base = (gpuInfo.scaleFilter != null && gpuInfo.scaleFilter != 'scale')
        ? '$hwScale=$resolution'
        : 'scale=$resolution:force_original_aspect_ratio=increase,crop=$resolution';
    
    if (hflip) base += ',hflip';
    
    if (isHdr) {
      final download = gpuInfo.outputFormat != null ? 'hwdownload,format=p010le,' : '';
      return gpuInfo.hasZscale
          ? '$download$base,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=yuv420p'
          : '$download$base,format=yuv420p';
    } else {
      final download = gpuInfo.outputFormat != null ? 'hwdownload,format=nv12,' : '';
      return '$download$base,format=yuv420p';
    }
  }

  @override
  List<String> getEncoderArgs(GpuInfo gpuInfo) {
    return ['-b:v', '10M', '-realtime', '1'];
  }

  @override
  String getPreferredPixFmt(GpuInfo gpuInfo) {
    return gpuInfo.preferredPixFmt;
  }
}
