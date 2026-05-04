import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/execution_result.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/ffmpeg_options.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';

abstract class VideoToolkit {
  /// Thao tác phóng to/thu nhỏ. Hỗ trợ kích thước cố định hoặc theo tỉ lệ (iwScale) hoặc expression tùy chỉnh.
  String scale(int width, int height, {double? iwScale, String? expression});

  /// Thao tác xoay
  String rotate(double angle, {int? ow, int? oh});

  /// Hiệu ứng mờ dần (Fade)
  String fade({required String type, required double start, required double duration});

  /// Vẽ khung viền (Drawbox)
  String drawbox({required String c, required int t});

  /// Helper chuyển đổi màu sang Hex string (FFmpeg format)
  String colorToHex(dynamic color);

  /// Thao tác cắt khung hình
  String crop(int width, int height, int x, int y);

  /// Thao tác lật ngang
  String hflip();

  /// Chuẩn bị đầu vào để ghép nối nhiều video (Dùng Demuxer Concat)
  void buildConcatInput(FfmpegInputArgs inputs, List<String> paths, String tempDir, int index);

  void buildIndividualInputs(FfmpegInputArgs inputs, List<String> segmentPaths);

  /// Thao tác điều chỉnh tốc độ
  String adjustSpeed(double pts);

  /// Điều chỉnh Brightness, Contrast, Saturation, Gamma
  String eq({double brightness = 0.0, double contrast = 1.0, double saturation = 1.0, double gamma = 1.0});

  /// Điều chỉnh Hue, Saturation
  String hue({double? hueShift, double? saturation});

  /// Hiệu ứng tối góc (Vignette)
  String vignette(double angle);

  /// Áp dụng LUT 3D từ file
  String lut3d(String lutFilePath);

  /// Chồng lớp (Overlay) - Tự động chọn filter phù hợp phần cứng
  String overlay({String? x, String? y, String? enable, bool shortest = false});

  /// Xây dựng toàn bộ chuỗi Overlay từ CompositionPlan
  String buildOverlayChain(CompositionPlan plan, String inputLabel);

  /// Xây dựng toàn bộ chuỗi Mix Audio từ CompositionPlan
  String buildAudioMixChain(CompositionPlan plan);

  /// Xây dựng chuỗi filter cơ bản (Scale, Speed)
  String buildBaseFilter(CompositionPlan plan);

  /// Xây dựng chuỗi chỉnh màu (Color Grading)
  String buildColorGradingChain(CompositionPlan plan);
  
  /// Định dạng pixel ưu tiên cho phần cứng này
  String getPreferredPixelFormat();

  /// Thực thi tác vụ (FFmpeg, API, etc.)
  Future<ExecutionResult> runToolkit(
    List<String> args,
    VideoBatchExecutionContext context, {
    void Function(String)? onLog,
    void Function(double)? onProgress,
    int? targetDuration,
  });
}
