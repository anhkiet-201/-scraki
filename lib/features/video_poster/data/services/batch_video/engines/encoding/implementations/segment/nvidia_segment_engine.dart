import 'package:scraki/features/video_poster/data/services/batch_video/engines/encoding/video_segment_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

class NvidiaSegmentEngine implements VideoSegmentEngine {
  @override
  String buildSegmentFilter({
    required bool isHdr,
    required bool hflip,
    required int width,
    required int height,
    required GpuInfo gpuInfo,
  }) {
    final String hwScale = gpuInfo.scaleFilter ?? 'scale';
    final String targetFormat = (gpuInfo.outputFormat == null || gpuInfo.outputFormat == 'cuda') ? 'nv12' : gpuInfo.outputFormat!;

    if (gpuInfo.hasCudaFilters) {
      if (isHdr) {
        // HDR to SDR: Chạy 100% trên nhân CUDA bằng tonemap_cuda
        String filter = 'tonemap_cuda=format=$targetFormat:p=bt709:t=bt709:m=bt709';
        
        // Sau đó thực hiện scale
        filter += ',$hwScale=w=$width:h=$height';
        
        // Và lật hình nếu cần (sử dụng transpose_cuda chuẩn)
        if (hflip) {
          filter += ',transpose_cuda=dir=hflip';
        }
        return filter;
      }

      // Luồng non-HDR: Chạy 100% trên CUDA
      List<String> filters = [];
      
      // 1. Scale và Format conversion ngay trên GPU
      filters.add('$hwScale=w=$width:h=$height:format=$targetFormat');

      // 2. Flip trên GPU bằng transpose_cuda
      if (hflip) {
        filters.add('transpose_cuda=dir=hflip');
      }

      return filters.join(',');
    } else {
      // Fallback: Nếu không có CUDA filters, chạy scale/flip trên CPU
      final resolution = '$width:$height';
      final cpuScale = 'scale=$resolution:force_original_aspect_ratio=increase,crop=$resolution${hflip ? ",hflip" : ""}';
      
      if (isHdr && gpuInfo.hasZscale) {
        // HDR Tonemap trên CPU tương tự CpuSegmentEngine
        return '$cpuScale,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=nv12';
      }
      return '$cpuScale,format=nv12';
    }
  }

  @override
  List<String> getSegmentEncoderArgs(GpuInfo gpuInfo) {
    return [
      '-c:v', 'h264_nvenc',
      '-preset', 'p1', // Tối ưu tốc độ cho giai đoạn cắt/segment
      '-tune', 'll',   // Low latency
      '-b:v', '10M',
      '-maxrate', '12M',
      '-bufsize', '20M',
    ];
  }

  @override
  String getPreferredPixFmt(GpuInfo gpuInfo) {
    return gpuInfo.outputFormat ?? gpuInfo.preferredPixFmt;
  }
}
