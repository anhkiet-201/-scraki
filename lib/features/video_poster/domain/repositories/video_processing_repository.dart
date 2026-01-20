import 'dart:typed_data';
import '../entities/video_composition.dart';

abstract class VideoProcessingRepository {
  /// Generates a video based on the composition.
  /// [overlayPng] is the captured preview PNG to overlay on the video.
  /// Returns the path to the generated video file.
  Future<String> generateVideo(
    VideoComposition composition,
    Uint8List overlayPng,
  );

  /// Generates a thumbnail/preview for the composition.
  Future<String?> generatePreview(VideoComposition composition);

  Future<String> extractThumbnail(String videoPath);

  /// Gets the duration of a video file.
  Future<Duration> getVideoDuration(String videoPath);
}
