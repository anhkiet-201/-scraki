import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'video_hardware_capability_resolver.dart';

@LazySingleton(as: VideoHardwareCapabilityResolver, env: ['macos'])
class MacOSVideoHardwareCapabilityResolver implements VideoHardwareCapabilityResolver {
  @override
  String get ffmpegBin => 'ffmpeg';

  @override
  String get ffprobeBin => 'ffprobe';

  GpuInfo? _cachedGpuInfo;
  List<String>? _availableFilters;

  @override
  GpuInfo? get gpuInfo => _cachedGpuInfo;

  @override
  Future<GpuInfo> resolve() async {
    final cached = _cachedGpuInfo;
    if (cached != null) return cached;
    
    final filters = await _getAvailableFilters();
    final hasZscale = filters.contains('zscale');

    // Apple Silicon / Intel Mac: VideoToolbox encode.
    _cachedGpuInfo = (
      name: 'Apple VideoToolbox',
      encoder: 'h264_videotoolbox',
      hwaccel: 'videotoolbox',
      scaleFilter: 'scale',
      outputFormat: null,
      hasZscale: hasZscale,
      hasCudaFilters: false,
      preferredPixFmt: 'yuv420p',
      maxConcurrentEncodes: Platform.numberOfProcessors.clamp(2, 8),
    );

    
    final info = _cachedGpuInfo;
    if (info == null) {
      return (
        name: 'Apple VideoToolbox (Fallback)',
        encoder: 'h264_videotoolbox',
        hwaccel: 'videotoolbox',
        scaleFilter: 'scale',
        outputFormat: null,
        hasZscale: false,
        hasCudaFilters: false,
        preferredPixFmt: 'yuv420p',
        maxConcurrentEncodes: 2,
      );
    }
    return info;
  }

  @override
  Future<bool> checkFfmpeg() async {
    try {
      final result = await Process.run(ffmpegBin, ['-version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  void clearCache() {
    _cachedGpuInfo = null;
    _availableFilters = null;
  }

  Future<List<String>> _getAvailableFilters() async {
    if (_availableFilters != null) return _availableFilters!;
    try {
      final result = await Process.run(ffmpegBin, ['-filters']);
      if (result.exitCode != 0) return [];

      final output = result.stdout as String;
      final filterRegex = RegExp(
        r'^\s*[TSC.]{3}\s+([a-z0-9_]+)\s+',
        multiLine: true,
      );

      _availableFilters = filterRegex
          .allMatches(output)
          .map((m) => m.group(1))
          .whereType<String>()
          .toList();

      final filters = _availableFilters;
      return filters ?? [];
    } catch (_) {
      return [];
    }
  }
}
