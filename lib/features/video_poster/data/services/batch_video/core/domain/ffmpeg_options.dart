/// Base interface for encoder-specific FFmpeg options.
abstract class EncoderOptions {
  /// Converts the options into a list of command-line arguments.
  List<String> toArgs();
}

/// Encoder options for Apple's VideoToolbox hardware acceleration.
class VideoToolboxOptions extends EncoderOptions {
  /// The codec name (e.g., 'h264_videotoolbox').
  final String codec;
  /// Targeted video bitrate (e.g., '12M').
  final String bitrate;
  /// Whether to optimize for real-time encoding.
  final bool realtime;
  /// Optional H.264 profile.
  final int? profile;
  /// Optional number of B-frames.
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

/// Encoder options for NVIDIA's NVENC hardware acceleration.
class NvidiaNvencOptions extends EncoderOptions {
  /// The codec name (e.g., 'h264_nvenc').
  final String codec;
  /// Targeted video bitrate.
  final String bitrate;
  /// Encoding preset (e.g., 'p4').
  final String preset;
  /// Rate control mode (e.g., 'vbr').
  final String rc;
  /// Constant Quality parameter.
  final String cq;
  /// Number of B-frames.
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

/// Encoder options for CPU-based encoding using libx264.
class CpuLibx264Options extends EncoderOptions {
  /// Encoding preset (e.g., 'veryfast').
  final String preset;
  /// Constant Rate Factor (CRF) for quality control.
  final String crf;
  /// Number of B-frames.
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

/// A helper class to build and manage FFmpeg filter chains.
class FilterPipe {
  final List<String> _filters = [];

  /// Adds a single filter string to the pipe.
  void add(String filter) {
    if (filter.isNotEmpty) _filters.add(filter);
  }

  /// Adds multiple filter strings to the pipe.
  void addAll(Iterable<String> filters) {
    _filters.addAll(filters.where((f) => f.isNotEmpty));
  }

  /// Whether the pipe contains no filters.
  bool get isEmpty => _filters.isEmpty;

  @override
  String toString() => _filters.join(',');
}

/// Manages FFmpeg input files and global flags.
class FfmpegInputArgs {
  final List<String> _args = [];

  /// Adds an input file with optional format and extra arguments.
  void addInput(String path, {String? format, List<String>? extraArgs}) {
    if (format != null) _args.addAll(['-f', format]);
    if (extraArgs != null) _args.addAll(extraArgs);
    _args.addAll(['-i', path]);
  }

  /// Specialized method to add a concat demuxer input file.
  void addConcatInput(String filePath) {
    addInput(filePath, format: 'concat', extraArgs: ['-safe', '0']);
  }

  /// Adds a global or input-specific flag with an optional value.
  void addFlag(String flag, [String? value]) {
    _args.add(flag);
    if (value != null) _args.add(value);
  }

  /// Adds a list of raw arguments.
  void addAll(List<String> args) {
    _args.addAll(args);
  }

  /// Returns an unmodifiable list of all accumulated arguments.
  List<String> toArgs() => List.unmodifiable(_args);
}
