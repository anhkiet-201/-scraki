abstract class EncoderOptions {
  List<String> toArgs();
}

/// Cấu hình cho VideoToolbox (Apple Silicon)
class VideoToolboxOptions extends EncoderOptions {
  final String codec;
  final String bitrate;
  final bool realtime;
  final int? profile;
  final int? bFrames;

  VideoToolboxOptions({
    this.codec = 'h264_videotoolbox',
    required this.bitrate,
    this.realtime = true,
    this.profile,
    this.bFrames,
  });

  @override
  List<String> toArgs() {
    return [
      '-c:v', codec,
      if (realtime) ...['-realtime', '1'],
      '-b:v', bitrate,
      if (profile != null) ...['-profile:v', profile.toString()],
      if (bFrames != null) ...['-bf', bFrames.toString()],
      '-c:a', 'aac',
      '-b:a', '128k',
    ];
  }
}

/// Cấu hình cho Nvidia NVENC
class NvidiaNvencOptions extends EncoderOptions {
  final String codec;
  final String bitrate;
  final String preset;
  final String rc;
  final String cq;
  final int bFrames;

  NvidiaNvencOptions({
    this.codec = 'h264_nvenc',
    required this.bitrate,
    this.preset = 'p4',
    this.rc = 'vbr',
    this.cq = '24',
    this.bFrames = 2,
  });

  @override
  List<String> toArgs() {
    return [
      '-c:v', codec,
      '-preset', preset,
      '-rc', rc,
      '-cq', cq,
      '-b:v', bitrate,
      '-bf', bFrames.toString(),
      '-pix_fmt', 'yuv420p',
      '-c:a', 'aac',
      '-b:a', '128k',
    ];
  }
}

/// Cấu hình cho CPU (libx264)
class CpuLibx264Options extends EncoderOptions {
  final String preset;
  final String crf;
  final int bFrames;

  CpuLibx264Options({
    this.preset = 'veryfast',
    this.crf = '23',
    this.bFrames = 2,
  });

  @override
  List<String> toArgs() {
    return [
      '-c:v', 'libx264',
      '-preset', preset,
      '-crf', crf,
      '-bf', bFrames.toString(),
      '-pix_fmt', 'yuv420p',
      '-c:a', 'aac',
      '-b:a', '128k',
    ];
  }
}

/// Helper class để quản lý chuỗi Filter
class FilterPipe {
  final List<String> _filters = [];

  void add(String filter) {
    if (filter.isNotEmpty) _filters.add(filter);
  }

  void addAll(Iterable<String> filters) {
    _filters.addAll(filters.where((f) => f.isNotEmpty));
  }

  bool get isEmpty => _filters.isEmpty;

  @override
  String toString() => _filters.join(',');
}

/// Quản lý danh sách file đầu vào và các flag liên quan
class FfmpegInputArgs {
  final List<String> _args = [];

  void addInput(String path, {String? format, List<String>? extraArgs}) {
    if (format != null) _args.addAll(['-f', format]);
    if (extraArgs != null) _args.addAll(extraArgs);
    _args.addAll(['-i', path]);
  }

  void addConcatInput(String filePath) {
    addInput(filePath, format: 'concat', extraArgs: ['-safe', '0']);
  }

  void addFlag(String flag, [String? value]) {
    _args.add(flag);
    if (value != null) _args.add(value);
  }

  void addAll(List<String> args) {
    _args.addAll(args);
  }

  List<String> toArgs() => List.unmodifiable(_args);
}
