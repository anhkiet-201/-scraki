import 'package:freezed_annotation/freezed_annotation.dart';

part 'poster_data.freezed.dart';
part 'poster_data.g.dart';

@freezed
class PosterData with _$PosterData {
  const factory PosterData({
    required String jobTitle,
    required String companyName,
    required String location,
    required String salaryRange,

    /// Short bullet points (3-5 items)
    @Default([]) List<String> requirements,

    /// Short bullet points (3-5 items)
    @Default([]) List<String> benefits,

    required String contactInfo,

    // Optional: Background image URL or theme color preference
    String? backgroundUrl,
    String? qrCodeData,
    String? catchyHeadline,
    // Hidden field to store raw content for AI processing
    String? rawContent,
    // ID/Slug for fetching details
    String? slug,
    // Images extracted from details
    @Default([]) List<String> imageUrls,
    // AI generated TikTok Caption
    String? tikTokCaption,
  }) = _PosterData;

  factory PosterData.fromJson(Map<String, dynamic> json) =>
      _$PosterDataFromJson(json);
}
