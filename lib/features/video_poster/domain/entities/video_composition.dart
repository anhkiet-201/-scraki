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
  }) = _VideoComposition;
}
