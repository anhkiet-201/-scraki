import 'package:json_annotation/json_annotation.dart';

part 'freesound_response.g.dart';

@JsonSerializable()
class FreesoundResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<FreesoundSound> results;

  FreesoundResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory FreesoundResponse.fromJson(Map<String, dynamic> json) =>
      _$FreesoundResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FreesoundResponseToJson(this);
}

@JsonSerializable()
class FreesoundSound {
  final int id;
  final String name;
  final Map<String, String> previews;

  FreesoundSound({
    required this.id,
    required this.name,
    required this.previews,
  });

  String get previewUrl => previews['preview-hq-mp3'] ?? '';

  factory FreesoundSound.fromJson(Map<String, dynamic> json) =>
      _$FreesoundSoundFromJson(json);

  Map<String, dynamic> toJson() => _$FreesoundSoundToJson(this);
}
