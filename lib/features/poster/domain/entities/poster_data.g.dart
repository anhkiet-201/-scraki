// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poster_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PosterData _$PosterDataFromJson(Map<String, dynamic> json) => _PosterData(
  jobTitle: json['jobTitle'] as String,
  companyName: json['companyName'] as String,
  location: json['location'] as String,
  salaryRange: json['salaryRange'] as String,
  requirements:
      (json['requirements'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  benefits:
      (json['benefits'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  contactInfo: json['contactInfo'] as String,
  backgroundUrl: json['backgroundUrl'] as String?,
  qrCodeData: json['qrCodeData'] as String?,
  catchyHeadline: json['catchyHeadline'] as String?,
  rawContent: json['rawContent'] as String?,
  slug: json['slug'] as String?,
  imageUrls:
      (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  tikTokCaption: json['tikTokCaption'] as String?,
);

Map<String, dynamic> _$PosterDataToJson(_PosterData instance) =>
    <String, dynamic>{
      'jobTitle': instance.jobTitle,
      'companyName': instance.companyName,
      'location': instance.location,
      'salaryRange': instance.salaryRange,
      'requirements': instance.requirements,
      'benefits': instance.benefits,
      'contactInfo': instance.contactInfo,
      'backgroundUrl': instance.backgroundUrl,
      'qrCodeData': instance.qrCodeData,
      'catchyHeadline': instance.catchyHeadline,
      'rawContent': instance.rawContent,
      'slug': instance.slug,
      'imageUrls': instance.imageUrls,
      'tikTokCaption': instance.tikTokCaption,
    };
