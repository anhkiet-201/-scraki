import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

abstract class VideoHardwareCapabilityResolver {
  String get ffmpegBin;
  String get ffprobeBin;
  
  Future<GpuInfo> getGpuInfo();
  Future<bool> checkFfmpeg();
  void clearCache();
}
