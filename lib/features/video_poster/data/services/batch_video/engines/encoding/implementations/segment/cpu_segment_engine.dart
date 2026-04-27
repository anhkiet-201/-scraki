import 'package:scraki/features/video_poster/data/services/batch_video/engines/encoding/video_segment_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

class CpuSegmentEngine implements VideoSegmentEngine {
  @override
  String buildSegmentFilter({
    required bool isHdr,
    required bool hflip,
    required int width,
    required int height,
    required GpuInfo gpuInfo,
  }) {
    final resolution = '$width:$height';
    final cpuScale = 'scale=$resolution:force_original_aspect_ratio=increase,crop=$resolution${hflip ? ",hflip" : ""}';
    
    return (isHdr && gpuInfo.hasZscale)
        ? '$cpuScale,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=yuv420p'
        : '$cpuScale,format=yuv420p';
  }

  @override
  List<String> getSegmentEncoderArgs(GpuInfo gpuInfo) {
    return [
      '-c:v', 'libx264',
      '-preset', 'ultrafast',
      '-b:v', '10M',
    ];
  }

  @override
  String getPreferredPixFmt(GpuInfo gpuInfo) {
    return 'yuv420p';
  }
}
