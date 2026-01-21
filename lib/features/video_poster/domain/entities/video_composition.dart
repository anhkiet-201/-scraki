import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/video_poster/domain/entities/anti_reup_config.dart';

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
    @Default(0.1) double requirementsX,
    @Default(0.4) double requirementsY,
    @Default(0.1) double benefitsX,
    @Default(0.6) double benefitsY,
    @Default(0.5) double contactX,
    @Default(0.92) double contactY,
    @Default(0.5) double headlineX,
    @Default(0.08) double headlineY,
    @Default(0.5) double locationX,
    @Default(0.3) double locationY,

    // Effects
    @Default(1.2) double saturation,
    @Default(1.0) double contrast,
    @Default(1.0) double playbackSpeed,
    @Default(0.0) double zoomIntensity,

    // Anti-Reup Configuration
    @Default(AntiReupConfig()) AntiReupConfig antiReupConfig,
    @Default(0) int randomSeed,
  }) = _VideoComposition;
}
