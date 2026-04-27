import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

abstract class VideoEncodingEngine {
  /// Xây dựng chuỗi bộ lọc video (video filters -vf)
  String buildVideoFilter({
    required bool isHdr,
    required bool hflip,
    required int width,
    required int height,
    required GpuInfo gpuInfo,
  });

  /// Lấy các tham số cấu hình cho encoder (ví dụ bitrate, preset...)
  List<String> getEncoderArgs(GpuInfo gpuInfo);

  /// Pixel format ưu tiên cho engine này
  String getPreferredPixFmt(GpuInfo gpuInfo);
}
