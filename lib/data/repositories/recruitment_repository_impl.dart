import 'dart:convert';
import 'package:scraki/core/config/app_config.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/domain/repositories/recruitment_repository.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';

@LazySingleton(as: RecruitmentRepository)
class RecruitmentRepositoryImpl implements RecruitmentRepository {
  final Dio _dio;
  // Note: GenerativeModel should ideally be injected or configured via a provider.
  // For simplicity, we initialize it here or inject a wrapper.
  // We'll initialize it lazily or assume the key is passed/injected.
  final String _geminiApiKey = AppConfig.geminiApiKey;
  late final GenerativeModel _geminiModel;

  RecruitmentRepositoryImpl(this._dio) {
    _geminiModel = GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: _geminiApiKey,
    );
  }

  @override
  Future<Either<Failure, List<PosterData>>> fetchJobsFromApi() async {
    try {
      // TODO: Add timeout and better error handling
      final response = await _dio.get<Map<String, dynamic>>(
        'https://timviec.vieclamhr.com/api/jobs',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;

        final posters = items.map((item) {
          String formatCurrency(dynamic value) {
            if (value == null) return '';
            final number = int.tryParse(value.toString()) ?? 0;
            if (number >= 1000000) {
              return '${(number / 1000000).toStringAsFixed(0)} Tr';
            }
            return number.toString();
          }

          final min = formatCurrency(item['salaryMin']);
          final max = formatCurrency(item['salaryMax']);

          final salaryRange = (min.isNotEmpty && max.isNotEmpty)
              ? '$min - $max'
              : (min.isNotEmpty ? '> $min' : 'Thỏa thuận');

          // We'll strip HTML tags from content for a rough description, or use AI later to summarize it.
          // For now, map basic fields.
          return PosterData(
            jobTitle: (item['title'] as String?) ?? 'Tuyển Dụng',
            companyName: 'VieclamHR',
            location: (item['location'] as String?) ?? '',
            salaryRange: salaryRange,
            requirements: ['Xem chi tiết tại link'],
            benefits: [],
            contactInfo: 'Nộp hồ sơ trực tuyến',
            rawContent:
                (item['content'] as String?) ??
                (item['description'] as String?) ??
                '',
            slug: item['slug'] as String?,
          );
        }).toList();

        return right(posters);
      } else {
        return left(ApiFailure('API Error: ${response.statusCode}'));
      }
    } catch (e, stackTrace) {
      return left(ApiFailure('Failed to fetch jobs', e, stackTrace));
    }
  }

  @override
  Future<Either<Failure, PosterData>> parseJobDescription(
    String rawText,
  ) async {
    try {
      final prompt =
          '''
      You are a professional recruitment poster designer. Extract and CREATE the following information from this job description.
      Return strictly valid JSON.
      
      CRITICAL COMPLIANCE RULES:
      1. Ensure content complies with Community Standards and Local Laws.
      2. PREVENT SCAM FLAGGING: Do NOT use phrases like "Việc nhẹ lương cao", "Kiếm tiền dễ dàng", "Không cần kinh nghiệm lương khủng", or massive unverifiable promises.
      3. Tone: Professional, Authentic, Trustworthy, and Enthusiastic.
      
      Fields:
      - jobTitle (String): The official job title.
      - catchyHeadline (String): A short, exciting, professional, and clear headline (2-5 words). Example: "CƠ HỘI NGHỀ NGHIỆP", "TUYỂN DỤNG GẤP", "THU NHẬP HẤP DẪN", "ĐỒNG ĐỘI MỚI". ALL CAPS.
      - companyName (String): Name of the company.
      - location (String): location of work.
      - salaryRange (String): e.g. "10 - 15 Triệu". Consistent with market rates.
      - requirements (List<String>): Max 5 brief bullet points.
      - benefits (List<String>): Max 5 brief bullet points.
      - contactInfo (String): Email or Phone or Url.
      - tikTokCaption (String): A viral, engaging caption for TikTok (max 50 words). Include emojis and 3-5 relevant hashtags (e.g. #ViecLam #BinhDuong).
      
      If a field is missing, use empty string or empty list on JSON.
      
      Job Description:
      $rawText
      ''';

      final content = [Content.text(prompt)];
      final response = await _geminiModel.generateContent(content);

      final text = response.text;
      if (text == null) {
        return left(const ParsingFailure('Empty response from AI'));
      }

      // Cleanup JSON markdown
      final cleanJson = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      try {
        final Map<String, dynamic> jsonMap =
            jsonDecode(cleanJson) as Map<String, dynamic>;
        final posterData = PosterData.fromJson(jsonMap);
        return right(posterData);
      } catch (e) {
        return left(const ParsingFailure('Failed to decode AI JSON response'));
      }
    } catch (e, stackTrace) {
      return left(ParsingFailure('Gemini Error', e, stackTrace));
    }
  }

  @override
  Future<Either<Failure, PosterData>> fetchJobDetail(String slug) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://timviec.vieclamhr.com/api/jobs/$slug',
      );

      if (response.statusCode == 200) {
        final item = response.data as Map<String, dynamic>;
        List<String> images = [];
        // Check standard 'images' list
        if (item['images'] != null && item['images'] is List) {
          images.addAll((item['images'] as List).map((e) => e.toString()));
        }
        // Check 'galleries' (common in some APIs)
        if (images.isEmpty &&
            item['galleries'] != null &&
            item['galleries'] is List) {
          images.addAll((item['galleries'] as List).map((e) => e.toString()));
        }
        // Check single 'image' or 'thumbnail' or 'imageUrl'
        if (images.isEmpty) {
          if (item['imageUrl'] != null &&
              item['imageUrl'].toString().isNotEmpty) {
            images.add(item['imageUrl'].toString());
          } else if (item['image'] != null &&
              item['image'].toString().isNotEmpty) {
            images.add(item['image'].toString());
          } else if (item['thumbnail'] != null &&
              item['thumbnail'].toString().isNotEmpty) {
            images.add(item['thumbnail'].toString());
          }
        }
        return right(
          PosterData(
            jobTitle: (item['title'] as String?) ?? '',
            companyName: 'VieclamHR',
            location: (item['location'] as String?) ?? '',
            salaryRange: '',
            requirements: [],
            benefits: [],
            contactInfo: '',
            rawContent:
                (item['content'] as String?) ??
                (item['description'] as String?) ??
                '',
            slug: slug,
            imageUrls: images,
          ),
        );
      } else {
        return left(ApiFailure('Detail API Error: ${response.statusCode}'));
      }
    } catch (e, stackTrace) {
      return left(ApiFailure('Failed to fetch job detail', e, stackTrace));
    }
  }
}
