import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';

/// A comprehensive plan for composing multiple video segments into a final video.
/// 
/// This plan contains all the necessary data (file paths, configurations, and 
/// randomized parameters) required by a [Composition] engine to build the 
/// FFmpeg filter chains and execute the rendering.
class CompositionPlan {
  /// The index of the video in the current batch (0-indexed).
  final int outputIndex;
  /// List of temporary video segment file paths to be concatenated.
  final List<String> segmentPaths;
  /// List of durations for each segment in [segmentPaths].
  final List<double> segmentDurations;
  /// Directory where the final output video will be saved.
  final String outputDir;
  /// Directory for temporary intermediate files (like concat lists or text PNGs).
  final String tempDir;
  /// The user-defined configuration for this video (overlays, music, etc.).
  final BatchVideoConfig config;
  /// Path to the ambient sound file, if any.
  final String? ambientAudioPath;
  
  /// Randomized parameters generated to make each video unique (Spoofing).
  final CompositionParams params;
  
  /// Paths to pre-rendered PNG files for text overlays.
  final List<String> textOverlayPaths;
  /// Whether the plan includes a custom background music file.
  final bool hasCustomAudio;
  /// Whether the plan includes ambient sound.
  final bool hasAmbientAudio;

  CompositionPlan({
    required this.outputIndex,
    required this.segmentPaths,
    required this.segmentDurations,
    required this.outputDir,
    required this.tempDir,
    required this.config,
    required this.params,
    this.ambientAudioPath,
    required this.textOverlayPaths,
    required this.hasCustomAudio,
    required this.hasAmbientAudio,
  });

  /// Returns the absolute path where the final rendered video should be saved.
  String get finalOutputPath => 
      '$outputDir/tik_final_${outputIndex.toString().padLeft(3, '0')}.mp4';
}

/// A set of randomized parameters used to diversify video output.
/// 
/// These parameters influence color grading, Ken Burns effects (zoom/pan), 
/// audio spoofing, and metadata to help bypass duplicate content detection.
class CompositionParams {
  /// The calculated total duration of the final video.
  final int targetDuration;
  /// Presentation Time Stamp multiplier (used for subtle speed adjustments).
  final double pts;
  /// Brightness adjustment offset.
  final double brightness;
  /// Contrast adjustment multiplier.
  final double contrast;
  /// Group of Pictures size for the encoder.
  final int gopSize;
  /// Number of B-frames for the encoder.
  final int bFrames;
  /// ISO 8601 creation time string to be embedded in metadata.
  final String creationTime;
  /// Audio profile for pitch and equalizer spoofing.
  final AudioSpoofProfile audioProfile;
  /// Hue shift adjustment.
  final double hueShift;
  /// Saturation factor.
  final double satFactor;
  /// Vignette effect angle.
  final double vignetteAngle;
  /// Base zoom factor for Ken Burns effect.
  final double zoomVal;
  /// Horizontal jitter offset for micro-cropping.
  final double cropJitterX;
  /// Vertical jitter offset for micro-cropping.
  final double cropJitterY;
  /// Starting X coordinate for panning (0.0 to 1.0).
  final double panStartX;
  /// Starting Y coordinate for panning (0.0 to 1.0).
  final double panStartY;
  /// Ending X coordinate for panning (0.0 to 1.0).
  final double panEndX;
  /// Ending Y coordinate for panning (0.0 to 1.0).
  final double panEndY;
  /// Duration of transitions between segments.
  final double transitionDuration;
  /// Optional path to a 3D LUT file for professional color grading.
  final String? lutFilePath;
  /// Gamma adjustment for Red channel.
  final double? gammaR;
  /// Gamma adjustment for Green channel.
  final double? gammaG;
  /// Gamma adjustment for Blue channel.
  final double? gammaB;

  CompositionParams({
    required this.targetDuration,
    required this.pts,
    required this.brightness,
    required this.contrast,
    required this.gopSize,
    required this.bFrames,
    required this.creationTime,
    required this.audioProfile,
    required this.hueShift,
    required this.satFactor,
    required this.vignetteAngle,
    required this.zoomVal,
    required this.cropJitterX,
    required this.cropJitterY,
    required this.panStartX,
    required this.panStartY,
    required this.panEndX,
    required this.panEndY,
    required this.transitionDuration,
    this.lutFilePath,
    this.gammaR,
    this.gammaG,
    this.gammaB,
  });
}
