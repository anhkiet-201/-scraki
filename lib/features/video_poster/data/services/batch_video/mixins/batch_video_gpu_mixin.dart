import 'dart:io';

typedef GpuInfo = ({
  String encoder,
  String? hwaccel,
  String? scaleFilter,
  String? outputFormat,
  bool hasZscale,
  bool hasCudaFilters,
});

mixin BatchVideoGpuMixin {
  static String get ffmpegBin => Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
  static String get ffprobeBin => Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';

  GpuInfo? _cachedGpuInfo;

  Future<GpuInfo> getGpuInfo() async {
    return _cachedGpuInfo ??= await resolveGpuInfo();
  }

  Future<GpuInfo> resolveGpuInfo() async {
    final filters = await getAvailableFilters();
    final hasZscale = filters.contains('zscale');
    final hasCudaFilters = filters.contains('scale_cuda') && filters.contains('hwupload_cuda');

    if (Platform.isMacOS) {
      return (
        encoder: 'h264_videotoolbox',
        hwaccel: 'videotoolbox',
        scaleFilter: 'scale_vt',
        outputFormat: null,
        hasZscale: hasZscale,
        hasCudaFilters: false,
      );
    }
    if (Platform.isWindows) {
      final encoders = await getAvailableEncoders();
      if (encoders.contains('h264_nvenc')) {
        return (
          encoder: 'h264_nvenc',
          hwaccel: 'cuda',
          scaleFilter: hasCudaFilters ? 'scale_cuda' : 'scale',
          outputFormat: hasCudaFilters ? 'cuda' : null,
          hasZscale: hasZscale,
          hasCudaFilters: hasCudaFilters,
        );
      }
      if (encoders.contains('h264_qsv')) {
        final hasQsvFilters = filters.contains('vpp_qsv');
        return (
          encoder: 'h264_qsv',
          hwaccel: 'qsv',
          scaleFilter: hasQsvFilters ? 'vpp_qsv' : 'scale',
          outputFormat: hasQsvFilters ? 'qsv' : null,
          hasZscale: hasZscale,
          hasCudaFilters: false,
        );
      }
      if (encoders.contains('h264_amf')) {
        return (
          encoder: 'h264_amf',
          hwaccel: 'd3d11va',
          scaleFilter: null,
          outputFormat: null,
          hasZscale: hasZscale,
          hasCudaFilters: false,
        );
      }
    }
    return (
      encoder: 'libx264',
      hwaccel: null,
      scaleFilter: null,
      outputFormat: null,
      hasZscale: hasZscale,
      hasCudaFilters: false,
    );
  }

  List<String>? _availableEncoders;
  List<String>? _availableFilters;

  Future<List<String>> getAvailableEncoders() async {
    if (_availableEncoders != null) return _availableEncoders!;
    try {
      final result = await Process.run(ffmpegBin, ['-encoders']);
      final output = result.stdout as String;
      _availableEncoders =
          output
              .split('\n')
              .where((l) => l.contains('V....D'))
              .map((l) => l.split(' ').where((s) => s.isNotEmpty).skip(1).first)
              .toList();
      return _availableEncoders!;
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> getAvailableFilters() async {
    if (_availableFilters != null) return _availableFilters!;
    try {
      final result = await Process.run(ffmpegBin, ['-filters']);
      if (result.exitCode != 0) return [];
      
      final output = result.stdout as String;
      final filterRegex = RegExp(r'^\s*[TSC.]{3}\s+([a-z0-9_]+)\s+', multiLine: true);
      
      _availableFilters = filterRegex.allMatches(output)
          .map((m) => m.group(1))
          .whereType<String>()
          .toList();
          
      return _availableFilters!;
    } catch (_) {
      return [];
    }
  }

  Future<bool> checkFfmpeg() async {
    try {
      final result = await Process.run(ffmpegBin, ['-version']);
      if (result.exitCode == 0) {
        // Log capabilities once
        final gpu = await getGpuInfo();
        print('🚀 Video Engine Initialized: Encoder=${gpu.encoder}, Zscale=${gpu.hasZscale}, CudaFilters=${gpu.hasCudaFilters}');
      }
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  void clearGpuCache() {
    _cachedGpuInfo = null;
  }
}
