import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';

abstract class VideoBatchPipeline {
  /// Lên kế hoạch: Phân tích video nguồn và tạo danh sách segment
  Future<void> plan({
    required List<String> sourceVideoPaths,
    required BatchVideoConfig config,
  });

  /// Thực thi: Cắt tất cả các segment cần thiết
  Future<void> executeCutSegments();

  /// Thực thi: Ghép các video thành phẩm
  Future<void> executeRender();

  /// Luồng sự kiện log/progress
  Stream<String> get events;

  /// Hủy bỏ quá trình
  void cancel();

  /// Dọn dẹp tài nguyên và file tạm
  Future<void> cleanup();
}
