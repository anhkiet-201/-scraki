import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import 'package:injectable/injectable.dart';
import 'package:scraki/core/network/dio_client.dart';
import '../models/freesound_response.dart';

@injectable
class AmbientAudioService {
  final DioClient _dioClient;
  final Random _random = Random();

  AmbientAudioService(this._dioClient);

  /// Tải [count] file audio ambient từ Freesound
  Future<List<String>> fetchRandomAmbientAudios(
      int count, List<String> tags, {void Function(String)? onLog}) async {
    final apiKey = dotenv.env['FREESOUND_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      onLog?.call('  ⚠️ Không tìm thấy FREESOUND_API_KEY. Bỏ qua tải ambient audio.');
      return [];
    }

    final List<String> downloadedPaths = [];
    final tempDir = Directory.systemTemp;

    // Tải theo đợt (Batching: tối đa 5 file mỗi request để giảm API calls)
    while (downloadedPaths.length < count) {
      try {
        final tag = tags[_random.nextInt(tags.length)];
        final randomPage = _random.nextInt(5) + 1; // Random từ trang 1 đến 5
        
        // Hàm gọi API với tham số page truyền vào
        Future<FreesoundResponse?> fetchPage(int page) async {
          try {
            final response = await _dioClient.get<Map<String, dynamic>>(
              'https://freesound.org/apiv2/search/text/',
              queryParameters: {
                'query': tag,
                'filter': 'duration:[15.0 TO 60.0]',
                'fields': 'id,name,previews',
                'token': apiKey,
                'page_size': 50,
                'page': page,
              },
              options: Options(
                validateStatus: (status) => true,
              ),
            );

            if (response.statusCode == 200 && response.data != null) {
              return FreesoundResponse.fromJson(response.data ?? {});
            }
          } catch (e) {
            onLog?.call('    ⚠️ Lỗi gọi API Freesound (page $page): $e');
          }
          return null;
        }

        var freeseoundData = await fetchPage(randomPage);
        
        // Nếu trang ngẫu nhiên không có dữ liệu (tag ít kết quả hoặc 404), fallback về trang 1
        if ((freeseoundData == null || freeseoundData.results.isEmpty) && randomPage > 1) {
          freeseoundData = await fetchPage(1);
        }

        if (freeseoundData != null && freeseoundData.results.isNotEmpty) {
          // Xáo trộn danh sách kết quả để đảm bảo tính ngẫu nhiên
          final results = List<FreesoundSound>.from(freeseoundData.results)..shuffle(_random);
          
          // Lấy tối đa 5 file (hoặc số lượng còn thiếu)
          final needed = count - downloadedPaths.length;
          final batchSize = min(5, min(needed, results.length));
          final batchItems = results.take(batchSize).toList();

          onLog?.call('  🎵 Đang tải batch $batchSize files cho tag "$tag"...');

          // Tải song song các file trong batch (Parallel downloading)
          final downloadTasks = batchItems.map((item) async {
            final previewUrl = item.previewUrl;
            if (previewUrl.isEmpty) return null;

            final name = item.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
            final filePath = p.join(
              tempDir.path, 
              'scraki_ambient_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}_$name.mp3'
            );

            try {
              await _dioClient.download(previewUrl, filePath);
              return filePath;
            } catch (e) {
              onLog?.call('    ❌ Lỗi tải file "${item.name}": $e');
              return null;
            }
          }).toList();

          final batchPaths = await Future.wait(downloadTasks);
          final validPaths = batchPaths.whereType<String>().toList();
          
          if (validPaths.isEmpty) {
             onLog?.call('    ⚠️ Không tải được file nào trong batch hiện tại.');
             // Break để tránh loop vô hạn nếu lỗi file hàng loạt
             break;
          }

          downloadedPaths.addAll(validPaths);
          onLog?.call('  ✅ Hoàn tất tải ${validPaths.length}/$batchSize files cho tag "$tag"');
        } else {
          onLog?.call('  ⚠️ Không tìm thấy audio nào cho tag "$tag".');
          break; // Thoát nếu không tìm thấy kết quả nào cho tag hiện tại
        }
      } catch (e) {
        onLog?.call('  ❌ Lỗi xử lý ambient audio: $e');
        break; 
      }
    }

    // Đảm bảo trả về đúng danh sách đã tải
    final results = <String>[];
    if (downloadedPaths.isNotEmpty) {
      for (int i = 0; i < count; i++) {
        results.add(downloadedPaths[i % downloadedPaths.length]);
      }
    }
    return results;
  }
}
