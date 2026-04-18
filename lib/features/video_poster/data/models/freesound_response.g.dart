// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'freesound_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FreesoundResponse _$FreesoundResponseFromJson(Map<String, dynamic> json) =>
    FreesoundResponse(
      count: (json['count'] as num).toInt(),
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => FreesoundSound.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FreesoundResponseToJson(FreesoundResponse instance) =>
    <String, dynamic>{
      'count': instance.count,
      'next': instance.next,
      'previous': instance.previous,
      'results': instance.results,
    };

FreesoundSound _$FreesoundSoundFromJson(Map<String, dynamic> json) =>
    FreesoundSound(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      previews: Map<String, String>.from(json['previews'] as Map),
    );

Map<String, dynamic> _$FreesoundSoundToJson(FreesoundSound instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'previews': instance.previews,
    };
