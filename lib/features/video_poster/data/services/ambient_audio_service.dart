import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;

class AmbientAudioService {
  final Dio _dio = Dio();
  final Random _random = Random();

  /// Tải [count] file audio ambient từ Freesound
  Future<List<String>> fetchRandomAmbientAudios(
      int count, List<String> tags, {void Function(String)? onLog}) async {
    final apiKey = dotenv.env['FREESOUND_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      onLog?.call('  ⚠️ Không tìm thấy FREESOUND_API_KEY trong .env. Bỏ qua tải ambient audio.');
      return [];
    }

    final List<String> downloadedPaths = [];
    final tempDir = Directory.systemTemp;

    for (int i = 0; i < count; i++) {
      try {
        final tag = tags[_random.nextInt(tags.length)];
        final randomPage = _random.nextInt(5) + 1; // Random từ trang 1 đến 5
        
        // Hàm gọi API với tham số page truyền vào
        Future<Response> fetchPage(int page) {
          return _dio.get(
            'https://freesound.org/apiv2/search/text/',
            queryParameters: {
              'query': tag,
              'filter': 'duration:[15.0 TO 60.0]',
              'fields': 'id,name,previews',
              'token': apiKey,
              'page_size': 50,
              'page': page,
            },
          );
        }

        var response = await fetchPage(randomPage);
        var results = response.data['results'] as List;

        // Nếu trang ngẫu nhiên không có dữ liệu (tag ít kết quả), fallback về trang 1
        if (results.isEmpty && randomPage > 1) {
          response = await fetchPage(1);
          results = response.data['results'] as List;
        }

        if (response.statusCode == 200 && results.isNotEmpty) {
          // Pick randoom từ mảng 50 kết quả
          final item = results[_random.nextInt(results.length)];
          final prevewUrl = item['previews']['preview-hq-mp3'] as String;
          final name = item['name']?.toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') ?? 'ambient';
          
          final filePath = p.join(
            tempDir.path, 
            'scraki_ambient_${DateTime.now().millisecondsSinceEpoch}_$name.mp3'
          );

          await _dio.download(prevewUrl, filePath);
          downloadedPaths.add(filePath);
          onLog?.call('  🎵 Tải nhạc nền "$tag": thành công (${i + 1}/$count)');
        } else {
          onLog?.call('  ⚠️ Không tìm thấy audio nào cho tag "$tag".');
        }
      } catch (e) {
        onLog?.call('  ❌ Lỗi tải ambient audio: $e');
      }
    }

    // Đảm bảo đủ file (có thể tải bị thiếu do lỗi kết nối)
    final results = <String>[];
    for (int i = 0; i < count; i++) {
        if (downloadedPaths.isNotEmpty) {
           results.add(downloadedPaths[i % downloadedPaths.length]);
        }
    }
    return results;
  }
}
