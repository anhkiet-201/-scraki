import 'dart:io';

typedef GpuInfo = ({
  String encoder,
  String? hwaccel,
  String? scaleFilter,
  String? outputFormat,
  bool hasZscale,
  bool hasCudaFilters,
  // Pixel format tối ưu cho encoder: 'nv12' với NVENC/VT, 'yuv420p' với libx264/QSV
  String preferredPixFmt,
  // Số lượng encode song song tối đa dựa trên hardware
  int maxConcurrentEncodes,
});

mixin BatchVideoGpuMixin {
  static String get ffmpegBin => Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
  static String get ffprobeBin =>
      Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';

  GpuInfo? _cachedGpuInfo;

  Future<GpuInfo> getGpuInfo() async {
    return _cachedGpuInfo ??= await resolveGpuInfo();
  }

  Future<GpuInfo> resolveGpuInfo() async {
    final filters = await getAvailableFilters();
    final hasZscale = filters.contains('zscale');
    final hasCudaFilters =
        filters.contains('scale_cuda') && filters.contains('hwupload_cuda');

    if (Platform.isMacOS) {
      // Apple Silicon: Media Engine decode + Software scale/filters + VideoToolbox encode.
      // - hwaccel: 'videotoolbox' giúp giảm tải CPU khi giải mã. Do ta dùng scale (software)
      //   nên FFmpeg sẽ tự động download frame xuống RAM (nv12) sau khi giải mã xong,
      //   nhờ đó các CPU filter (như trim, crop) hoạt động hoàn hảo mà không bị lỗi context.
      // - scale_vt bị bỏ vì không hỗ trợ tốt filter pipeline và không mang lại khác biệt lớn
      //   về tốc độ so với CPU NEON scale.
      return (
        encoder: 'h264_videotoolbox',
        hwaccel: 'videotoolbox',
        scaleFilter: 'scale',
        outputFormat: null,
        hasZscale: hasZscale,
        hasCudaFilters: false,
        preferredPixFmt: 'yuv420p',
        maxConcurrentEncodes: Platform.numberOfProcessors.clamp(2, 8),
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
          preferredPixFmt: 'nv12',
          maxConcurrentEncodes: hasCudaFilters ? 10 : 6,
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
          preferredPixFmt: 'yuv420p',
          maxConcurrentEncodes: 3,
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
          preferredPixFmt: 'yuv420p',
          maxConcurrentEncodes: 2,
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
      preferredPixFmt: 'yuv420p',
      maxConcurrentEncodes: Platform.numberOfProcessors.clamp(2, 8),
    );
  }

  List<String>? _availableEncoders;
  List<String>? _availableFilters;

  Future<List<String>> getAvailableEncoders() async {
    if (_availableEncoders != null) return _availableEncoders!;
    try {
      final result = await Process.run(ffmpegBin, ['-encoders']);
      final output = result.stdout as String;
      _availableEncoders = output
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
      final filterRegex = RegExp(
        r'^\s*[TSC.]{3}\s+([a-z0-9_]+)\s+',
        multiLine: true,
      );

      _availableFilters = filterRegex
          .allMatches(output)
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
        final gpu = await getGpuInfo();
        print(
          '🚀 Video Engine Initialized: Encoder=${gpu.encoder}, '
          'PixFmt=${gpu.preferredPixFmt}, MaxConcurrent=${gpu.maxConcurrentEncodes}, '
          'Zscale=${gpu.hasZscale}, CudaFilters=${gpu.hasCudaFilters}',
        );
      }
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  void clearGpuCache() {
    _cachedGpuInfo = null;
    _availableEncoders = null;
    _availableFilters = null;
  }
}
