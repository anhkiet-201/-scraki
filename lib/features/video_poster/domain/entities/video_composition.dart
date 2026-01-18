import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';

part 'video_composition.freezed.dart';

@freezed
class VideoComposition with _$VideoComposition {
  const factory VideoComposition({
    required String id,
    required List<String> sourceVideoPaths,
    required PosterData posterData,
    @Default(Duration(seconds: 20)) Duration targetDuration,
    @Default(true) bool randomize,
    @Default('default') String stylePreset,

    // Positioning (Relative 0.0 to 1.0)
    @Default(0.5) double titleX,
    @Default(0.15) double titleY,
    @Default(0.5) double salaryX,
    @Default(0.25) double salaryY,
    @Default(0.5) double companyX,
    @Default(0.85) double companyY,

    // Effects
    @Default(1.2) double saturation,
    @Default(1.0) double contrast,
    @Default(1.0) double playbackSpeed,
    @Default(0.0) double zoomIntensity,

    // Anti-Reup Randomization
    @Default(0.0) double noiseLevel,
    @Default(0.0) double hueShift,
    @Default(0.0) double brightnessDelta,
    @Default(0) int randomSeed,
  }) = _VideoComposition;
}
