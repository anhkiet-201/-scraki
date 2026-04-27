import 'package:scraki/features/video_poster/data/services/batch_video/engines/encoding/video_segment_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';


class QsvSegmentEngine implements VideoSegmentEngine {
  @override
  String buildSegmentFilter({
    required bool isHdr,
    required bool hflip,
    required int width,
    required int height,
    required GpuInfo gpuInfo,
  }) {
    final hwScale = gpuInfo.scaleFilter ?? 'vpp_qsv';
    
    if (isHdr) {
      final download = gpuInfo.outputFormat != null ? 'hwdownload,format=p010le,' : '';
      String base = gpuInfo.hasZscale
          ? '${download}zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=nv12,hwupload=extra_hw_frames=64'
          : '${download}format=nv12,hwupload=extra_hw_frames=64';
      
      String filter = '$base,$hwScale=w=$width:h=$height';
      if (hflip) filter += ',hflip'; 
      return filter;
    }

    String filter = '$hwScale=w=$width:h=$height';
    if (hflip) filter += ',hflip';
    return filter;
  }

  @override
  List<String> getSegmentEncoderArgs(GpuInfo gpuInfo) {
    return [
      '-c:v', 'h264_qsv',
      '-preset', 'veryfast',
      '-look_ahead', '0',
      '-b:v', '10M',
    ];
  }

  @override
  String getPreferredPixFmt(GpuInfo gpuInfo) {
    return 'nv12';
  }
}
