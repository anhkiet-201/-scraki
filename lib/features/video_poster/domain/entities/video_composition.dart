import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:scraki/features/video_poster/domain/entities/anti_reup_config.dart';

part 'video_composition.freezed.dart';

@freezed
abstract class VideoComposition with _$VideoComposition {
  const factory VideoComposition({
    required String id,
    required List<String> sourceVideoPaths,
    @Default(Duration(seconds: 20)) Duration targetDuration,
    @Default(true) bool randomize,
    @Default('default') String stylePreset,

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
