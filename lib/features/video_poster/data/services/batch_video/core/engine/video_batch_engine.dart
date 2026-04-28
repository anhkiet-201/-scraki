import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/execution_result.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/ffmpeg_options.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';

abstract class VideoBatchEngine {
  /// Khởi tạo engine với thông tin phần cứng
  Future<void> initialize();

  /// Bước: Cắt segment
  Future<ExecutionResult> cutSegment({
    required SegmentRequest request,
    required String outputPath,
    required VideoBatchExecutionContext context,
    void Function(String)? onLog,
  });

  /// Bước: Ghép video hoàn chỉnh (Render)
  Future<ExecutionResult> renderVideo({
    required CompositionPlan plan,
    required VideoBatchExecutionContext context,
    void Function(double)? onProgress,
    void Function(String)? onLog,
  });

  /// Các method xây dựng thành phần (để các Engine con implement logic đặc thù)
  String buildBaseVideoFilter(CompositionPlan plan);
  String buildColorFilter(CompositionPlan plan);
  String buildOverlayFilter(CompositionPlan plan);
  String buildAudioFilter(CompositionPlan plan);
  
  EncoderOptions getEncoderArgs(CompositionPlan plan);
}
