import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

typedef CompositionColorSettings = ({
  String? colorChannelMixer,
  String? curves,
  String? colorBalance,
  double brightness,
  double contrast,
  double? gamma,
  double? gammaR,
  double? gammaG,
  double? gammaB,
  double hueShift,
  double satFactor,
  double vignetteAngle,
});

abstract class VideoCompositionEngine {
  /// Xây dựng chuỗi bộ lọc phức hợp cho giai đoạn dựng video (composition)
  String buildCompositionFilter({
    required double zoomVal,
    required double randX,
    required double randY,
    required CompositionColorSettings colorSettings,
    required GpuInfo gpuInfo,
    required double pts,
  });

  /// Lấy các tham số cấu hình encoder tối ưu cho bản render cuối cùng
  List<String> getCompositionEncoderArgs(
    GpuInfo gpuInfo, {
    String? bitrate,
    String? maxRate,
    String? bufSize,
    int? gop,
  });

  /// Pixel format ưu tiên cho giai đoạn này
  String getPreferredPixFmt(GpuInfo gpuInfo);
}
