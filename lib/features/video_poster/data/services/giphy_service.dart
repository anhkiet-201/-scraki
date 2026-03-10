import 'package:dio/dio.dart';
import 'package:scraki/core/config/app_config.dart';

class GiphyService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.giphy.com/v1/gifs';

  Future<List<Map<String, dynamic>>> searchGifs(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final apiKey = AppConfig.giphyApiKey;
    if (apiKey.isEmpty) return [];

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/search',
        queryParameters: {
          'api_key': apiKey,
          'q': query,
          'limit': limit,
          'offset': offset,
          'rating': 'g',
          'lang': 'vi',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data!['data'] as List<dynamic>;
        return data.map((gif) {
          final gifMap = gif as Map<String, dynamic>;
          final images = gifMap['images'] as Map<String, dynamic>;
          return {
            'url': images['fixed_height']['url'] as String,
            'title': gifMap['title'] as String,
          };
        }).toList();
      }
    } catch (e) {
      print('Error searching Giphy: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getTrendingGifs({
    int limit = 20,
    int offset = 0,
  }) async {
    final apiKey = AppConfig.giphyApiKey;
    if (apiKey.isEmpty) return [];

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/trending',
        queryParameters: {
          'api_key': apiKey,
          'limit': limit,
          'offset': offset,
          'rating': 'g',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data!['data'] as List<dynamic>;
        return data.map((gif) {
          final gifMap = gif as Map<String, dynamic>;
          final images = gifMap['images'] as Map<String, dynamic>;
          return {
            'url': images['fixed_height']['url'] as String,
            'title': gifMap['title'] as String,
          };
        }).toList();
      }
    } catch (e) {
      print('Error getting trending Giphy: $e');
    }
    return [];
  }
}
