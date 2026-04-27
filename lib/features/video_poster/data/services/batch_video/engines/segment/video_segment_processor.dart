import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';

abstract class VideoSegmentProcessor {
  Future<void> runSegmentCut({
    required String input,
    required double startSeconds,
    required double duration,
    required String output,
    required bool hflip,
    required bool hasAudio,
    required String processName,
    required VideoBatchExecutionContext context,
    void Function(String)? onLogMsg,
  });
}
