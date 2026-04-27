import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import '../video_encoding_engine.dart';

class NvidiaVideoEngine implements VideoEncodingEngine {
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

    if (isHdr) {
      if (gpuInfo.hasZscale && gpuInfo.hasCudaFilters) {
        String filter = 'hwdownload,format=p010le,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=nv12,hwupload_cuda,$hwScale=$resolution';
        if (hflip) filter += ',hflip_cuda';
        return filter;
      } else {
        String base = gpuInfo.hasCudaFilters
            ? '$hwScale=$resolution'
            : 'scale=$resolution:force_original_aspect_ratio=increase,crop=$resolution';
        if (hflip) base += gpuInfo.hasCudaFilters ? ',hflip_cuda' : ',hflip';
        final download = gpuInfo.outputFormat != null ? 'hwdownload,format=p010le,' : '';
        return gpuInfo.hasZscale 
            ? '${download}zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=yuv420p,$base'
            : '${download}format=yuv420p,$base';
      }
    } else if (gpuInfo.hasCudaFilters) {
      final download = gpuInfo.outputFormat != null ? 'hwdownload,format=nv12,' : '';
      String filter = '$download$hwScale=$resolution';
      if (hflip) filter += ',hflip_cuda';
      filter += ',format=nv12';
      return filter;
    } else {
      String base = (gpuInfo.scaleFilter != null)
          ? '$hwScale=$resolution'
          : 'scale=$resolution:force_original_aspect_ratio=increase,crop=$resolution';
      if (hflip) base += ',hflip';
      final download = gpuInfo.outputFormat != null ? 'hwdownload,format=nv12,' : '';
      return '$download$base,format=yuv420p';
    }
  }

  @override
  List<String> getEncoderArgs(GpuInfo gpuInfo) {
    return ['-b:v', '10M', '-maxrate', '12M', '-bufsize', '20M'];
  }

  @override
  String getPreferredPixFmt(GpuInfo gpuInfo) {
    return gpuInfo.preferredPixFmt;
  }
}
