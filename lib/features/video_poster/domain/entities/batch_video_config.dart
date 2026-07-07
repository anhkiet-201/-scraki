import 'package:scraki/features/video_poster/domain/entities/custom_image_overlay.dart';
import 'package:scraki/features/video_poster/domain/entities/timed_overlay.dart';

enum BatchVideoOutputOption {
  tiktokVideo,
  tiktokAutocutSet,
  facebookGroupsVideo,
  facebookReelsVideo,
  facebookFeedsVideo,
}

extension BatchVideoOutputOptionExtension on BatchVideoOutputOption {
  String get label {
    switch (this) {
      case BatchVideoOutputOption.tiktokVideo:
        return 'TikTok Video';
      case BatchVideoOutputOption.tiktokAutocutSet:
        return 'TikTok Autocut Set';
      case BatchVideoOutputOption.facebookGroupsVideo:
        return 'Facebook Groups Video';
      case BatchVideoOutputOption.facebookReelsVideo:
        return 'Facebook Reels Video';
      case BatchVideoOutputOption.facebookFeedsVideo:
        return 'Facebook Feeds Video';
    }
  }
}

/// Configuration constants matching make-vid.sh defaults.
class BatchVideoConfig {
  final int minSegmentDuration; // seconds
  final int maxSegmentDuration; // seconds
  final int minVideoDuration; // minimum source video length to be valid
  final int minFinalDuration; // seconds
  final int maxFinalDuration; // seconds
  final int outputCount;
  final String? outputDir; // null = auto-generate with timestamp
  final List<TimedOverlay> textOverlays;
  final List<CustomImageOverlay> imageOverlays;
  final BatchVideoOutputOption outputOption;

  /// Đường dẫn file audio tùy chỉnh để mix vào video.
  /// null = chỉ dùng audio gốc (giảm về 5%).
  final String? customAudioPath;

  /// Âm lượng của nhạc tùy chỉnh (0.0 – 1.0).
  /// Mặc định 0.8 (~80%). Audio gốc sẽ được giữ ở 5%.
  final double customAudioVolume;

  /// Enable ambient audio (tiếng ồn trắng như chim, suối, mưa)
  final bool generateAmbientAudio;

  /// Bật filter sinh trộn màu ngẫu nhiên (chống re-up)
  final bool generateColorFilter;

  /// Các từ khoá để tìm kiếm âm thanh nền trên Freesound
  final List<String> ambientTags;

  const BatchVideoConfig({
    this.minSegmentDuration = 4,
    this.maxSegmentDuration = 6,
    this.minVideoDuration = 3,
    this.minFinalDuration = 35,
    this.maxFinalDuration = 45,
    this.outputCount = 10,
    this.outputDir,
    this.textOverlays = const [],
    this.imageOverlays = const [],
    this.outputOption = BatchVideoOutputOption.tiktokVideo,
    this.customAudioPath,
    this.customAudioVolume = 0.8,
    this.generateAmbientAudio = true,
    this.generateColorFilter = true,
    this.ambientTags = const [
      'forest birds', 'river stream', 'rain drops', 'wind through trees', 
      'ocean waves', 'crickets chirping', 'distant thunder', 'waterfall ambient',
      'night forest', 'breeze leaves', 'jungle ambience', 'field recording nature'
    ],
  });
}
