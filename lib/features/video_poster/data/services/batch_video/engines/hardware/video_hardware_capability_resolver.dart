import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

/// Interface for resolving system-specific hardware capabilities and FFmpeg paths.
abstract class VideoHardwareCapabilityResolver {
  /// Returns the absolute path to the FFmpeg executable.
  String get ffmpegBin;
  /// Returns the absolute path to the FFprobe executable.
  String get ffprobeBin;
  /// Returns cached GPU information if available.
  GpuInfo? get gpuInfo;
  
  /// Performs hardware detection and returns detailed [GpuInfo].
  Future<GpuInfo> resolve();
  /// Verifies that FFmpeg is installed and accessible.
  Future<bool> checkFfmpeg();
  /// Resets the cached hardware information.
  void clearCache();
}
