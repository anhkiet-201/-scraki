import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'video_hardware_capability_resolver.dart';

@LazySingleton(as: VideoHardwareCapabilityResolver, env: ['windows'])
class WindowsVideoHardwareCapabilityResolver implements VideoHardwareCapabilityResolver {
  @override
  String get ffmpegBin => 'ffmpeg.exe';

  @override
  String get ffprobeBin => 'ffprobe.exe';

  GpuInfo? _cachedGpuInfo;
  List<String>? _availableEncoders;
  List<String>? _availableFilters;

  @override
  GpuInfo? get gpuInfo => _cachedGpuInfo;

  @override
  Future<GpuInfo> resolve() async {
    final cached = _cachedGpuInfo;
    if (cached != null) return cached;
    
    final filters = await _getAvailableFilters();
    final encoders = await _getAvailableEncoders();
    
    final hasZscale = filters.contains('zscale');
    final hasCudaFilters = filters.contains('scale_cuda') && filters.contains('hwupload_cuda');

    if (encoders.contains('h264_nvenc')) {
      _cachedGpuInfo = (
        name: 'NVIDIA NVENC',
        encoder: 'h264_nvenc',
        hwaccel: 'cuda',
        scaleFilter: hasCudaFilters ? 'scale_cuda' : 'scale',
        outputFormat: hasCudaFilters ? 'cuda' : null,
        hasZscale: hasZscale,
        hasCudaFilters: hasCudaFilters,
        preferredPixFmt: 'nv12',
        maxConcurrentEncodes: hasCudaFilters ? 10 : 6,
      );
    } else if (encoders.contains('h264_qsv')) {
      final hasQsvFilters = filters.contains('vpp_qsv');
      _cachedGpuInfo = (
        name: 'Intel QSV',
        encoder: 'h264_qsv',
        hwaccel: 'qsv',
        scaleFilter: hasQsvFilters ? 'vpp_qsv' : 'scale',
        outputFormat: hasQsvFilters ? 'qsv' : null,
        hasZscale: hasZscale,
        hasCudaFilters: false,
        preferredPixFmt: 'yuv420p',
        maxConcurrentEncodes: 3,
      );
    } else if (encoders.contains('h264_amf')) {
      _cachedGpuInfo = (
        name: 'AMD AMF',
        encoder: 'h264_amf',
        hwaccel: 'd3d11va',
        scaleFilter: null,
        outputFormat: null,
        hasZscale: hasZscale,
        hasCudaFilters: false,
        preferredPixFmt: 'yuv420p',
        maxConcurrentEncodes: 2,
      );
    } else {
      _cachedGpuInfo = (
        name: 'CPU (Software)',
        encoder: 'libx264',
        hwaccel: null,
        scaleFilter: null,
        outputFormat: null,
        hasZscale: hasZscale,
        hasCudaFilters: false,
        preferredPixFmt: 'yuv420p',
        maxConcurrentEncodes: Platform.numberOfProcessors.clamp(2, 8),
      );
    }

    
    final info = _cachedGpuInfo;
    if (info == null) {
       // Fallback logic if somehow nullified
       return (
        name: 'CPU (Software)',
        encoder: 'libx264',
        hwaccel: null,
        scaleFilter: null,
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
    _availableEncoders = null;
    _availableFilters = null;
  }

  Future<List<String>> _getAvailableEncoders() async {
    if (_availableEncoders != null) return _availableEncoders!;
    try {
      final result = await Process.run(ffmpegBin, ['-encoders']);
      final output = result.stdout as String;
      _availableEncoders = output
          .split('\n')
          .where((l) => l.contains('V....D'))
          .map((l) => l.split(' ').where((s) => s.isNotEmpty).skip(1).first)
          .toList();
      final encoders = _availableEncoders;
      return encoders ?? [];
    } catch (_) {
      return [];
    }
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
