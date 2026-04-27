import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

abstract class VideoSegmentEngine {
  /// Xây dựng chuỗi bộ lọc video cho giai đoạn cắt clip (segment cut)
  String buildSegmentFilter({
    required bool isHdr,
    required bool hflip,
    required int width,
    required int height,
    required GpuInfo gpuInfo,
  });

  /// Lấy các tham số cấu hình encoder cho clip trung gian
  List<String> getSegmentEncoderArgs(GpuInfo gpuInfo);

  /// Pixel format ưu tiên cho giai đoạn này
  String getPreferredPixFmt(GpuInfo gpuInfo);
}
