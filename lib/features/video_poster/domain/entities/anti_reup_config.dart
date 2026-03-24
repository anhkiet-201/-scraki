import 'package:freezed_annotation/freezed_annotation.dart';

part 'anti_reup_config.freezed.dart';
part 'anti_reup_config.g.dart';

@freezed
abstract class AntiReupConfig with _$AntiReupConfig {
  const factory AntiReupConfig({
    /// Whether parameters should be randomized within safe ranges
    @Default(true) bool isRandomized,

    /// Playback speed multiplier (e.g., 1.05 = 5% faster)
    /// Range: 1.0 - 1.15
    @Default(1.05) double speedMultiplier,

    /// Enable visual noise generation
    @Default(true) bool enableVisualNoise,

    /// Intensity of visual noise (0.0 - 1.0)
    /// Recommended range: 0.03 - 0.1
    @Default(0.05) double noiseLevel,

    /// Intensity of color shifting (Saturation/Contrast/Brightness)
    /// Range: 0.0 - 1.0
    @Default(0.05) double colorShiftIntensity,

    /// Whether to shift audio pitch to match speed change
    /// (Usually recommended to be TRUE to avoid chipmunk effect if speed is high,
    /// but for small changes, maintaining pitch is better)
    /// actually for anti-detection, changing pitch slightly is better.
    @Default(true) bool enableAudioPitchShift,

    /// Whether to strip all metadata from the source file
    @Default(true) bool stripMetadata,

    /// Force output duration directly (in seconds).
    /// If null, duration is determined by source video * speedMultiplier.
    /// If set, video will be trimmed or looped to match this duration.
    double? targetDuration,
  }) = _AntiReupConfig;

  factory AntiReupConfig.fromJson(Map<String, dynamic> json) =>
      _$AntiReupConfigFromJson(json);
}
