import 'package:scraki/features/video_poster/data/services/batch_video/engines/encoding/video_segment_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

class VideoToolboxSegmentEngine implements VideoSegmentEngine {
  @override
  String buildSegmentFilter({
    required bool isHdr,
    required bool hflip,
    required int width,
    required int height,
    required GpuInfo gpuInfo,
  }) {
    final resolution = '$width:$height';
    final base = 'scale=$resolution:force_original_aspect_ratio=increase,crop=$resolution${hflip ? ",hflip" : ""}';
    
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
  List<String> getSegmentEncoderArgs(GpuInfo gpuInfo) {
    return [
      '-c:v', 'h264_videotoolbox',
      '-realtime', '1',
      '-b:v', '10M',
    ];
  }

  @override
  String getPreferredPixFmt(GpuInfo gpuInfo) {
    return 'yuv420p';
  }
}
