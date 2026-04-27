import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';

typedef ComposerResult = ({bool success, List<String> logs});

abstract class VideoBatchComposer {
  Future<ComposerResult> createOutputVideo({
    required int outputIndex,
    required List<String> segments,
    required String outputDir,
    required BatchVideoConfig config,
    required VideoBatchExecutionContext context,
    String? ambientAudioPath,
    void Function(double)? onProgress,
  });
}
