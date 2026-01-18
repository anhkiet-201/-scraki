import '../entities/video_composition.dart';

abstract class VideoProcessingRepository {
  /// Generates a video based on the composition.
  /// Returns the path to the generated video file.
  Future<String> generateVideo(VideoComposition composition);

  /// Generates a thumbnail/preview for the composition.
  Future<String?> generatePreview(VideoComposition composition);
}
