import 'package:scraki/features/video_poster/data/services/batch_video/engines/encoding/video_segment_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

class AmfSegmentEngine implements VideoSegmentEngine {
  @override
  String buildSegmentFilter({
    required bool isHdr,
    required bool hflip,
    required int width,
    required int height,
    required GpuInfo gpuInfo,
  }) {
    final resolution = '$width:$height';
    final scale = 'scale=$resolution:force_original_aspect_ratio=increase,crop=$resolution';
    
    if (isHdr && gpuInfo.hasZscale) {
      return '$scale,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=nv12';
    }
    
    String filter = scale;
    if (hflip) filter += ',hflip';
    return '$filter,format=nv12';
  }

  @override
  List<String> getSegmentEncoderArgs(GpuInfo gpuInfo) {
    return [
      '-c:v', 'h264_amf',
      '-usage', 'transcoding',
      '-quality', 'speed',
      '-b:v', '10M',
    ];
  }

  @override
  String getPreferredPixFmt(GpuInfo gpuInfo) {
    return 'nv12';
  }
}
