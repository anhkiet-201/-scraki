import 'dart:io';

typedef GpuInfo = ({String encoder, String? hwaccel, String? scaleFilter, String? outputFormat});

mixin BatchVideoGpuMixin {
  static String get ffmpegBin => Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
  static String get ffprobeBin => Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';

  GpuInfo? _cachedGpuInfo;

  Future<GpuInfo> getGpuInfo() async {
    return _cachedGpuInfo ??= await resolveGpuInfo();
  }

  Future<GpuInfo> resolveGpuInfo() async {
    if (Platform.isMacOS) {
      return (
        encoder: 'h264_videotoolbox',
        hwaccel: 'videotoolbox',
        scaleFilter: 'scale_vt',
        outputFormat: null,
      );
    }
    if (Platform.isWindows) {
      final encoders = await getAvailableEncoders();
      if (encoders.contains('h264_nvenc')) {
        return (
          encoder: 'h264_nvenc',
          hwaccel: 'cuda',
          scaleFilter: 'scale_cuda',
          outputFormat: 'cuda',
        );
      }
      if (encoders.contains('h264_qsv')) {
        return (
          encoder: 'h264_qsv',
          hwaccel: 'qsv',
          scaleFilter: 'vpp_qsv',
          outputFormat: 'qsv',
        );
      }
      if (encoders.contains('h264_amf')) {
        return (
          encoder: 'h264_amf',
          hwaccel: 'd3d11va',
          scaleFilter: null,
          outputFormat: null,
        );
      }
    }
    return (encoder: 'libx264', hwaccel: null, scaleFilter: null, outputFormat: null);
  }

  List<String>? _availableEncoders;

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

  Future<bool> checkFfmpeg() async {
    try {
      final result = await Process.run(ffmpegBin, ['-version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  void clearGpuCache() {
    _cachedGpuInfo = null;
  }
}
