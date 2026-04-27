import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

import '../video_encoding_engine.dart';

class CpuVideoEngine implements VideoEncodingEngine {
  @override
  String buildVideoFilter({
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
  List<String> getEncoderArgs(GpuInfo gpuInfo) {
    return ['-preset', 'ultrafast', '-b:v', '10M', '-maxrate', '12M', '-bufsize', '20M'];
  }

  @override
  String getPreferredPixFmt(GpuInfo gpuInfo) {
    return 'yuv420p';
  }
}
