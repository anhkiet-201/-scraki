import 'dart:math';

/// Hardware capability information for video encoding and filtering.
/// 
/// This record contains platform-specific encoder names, hardware acceleration 
/// flags, and optimal settings (like pixel formats) for a given GPU.
typedef GpuInfo = ({
  /// Human-readable name of the hardware (e.g., "NVIDIA GeForce RTX 3060")
  String name,
  /// FFmpeg encoder name (e.g., "h264_nvenc", "h264_videotoolbox")
  String encoder,
  /// Hardware acceleration type (e.g., "cuda", "videotoolbox", or null for CPU)
  String? hwaccel,
  /// Hardware-specific scale filter name (e.g., "scale_cuda")
  String? scaleFilter,
  /// Hardware-specific output format (e.g., "cuda")
  String? outputFormat,
  /// Whether zscale filter is available for HDR to SDR conversion
  bool hasZscale,
  /// Whether CUDA-specific filters like hflip_cuda are available
  bool hasCudaFilters,
  /// Optimal pixel format for the encoder: 'nv12' for HW, 'yuv420p' for CPU
  String preferredPixFmt,
  /// Maximum number of concurrent encode sessions allowed by hardware
  int maxConcurrentEncodes,
});

/// Planning data for a single video segment/slice before final composition.
/// 
/// Defines the source, timing, and basic manipulations (like flipping) for 
/// a portion of video that will be rendered into a temporary segment.
class SegmentRequest {
  /// Path to the source video file.
  final String sourcePath;
  /// Start time in seconds within the source video.
  final double startTime;
  /// Duration in seconds for this segment.
  final double duration;
  /// Whether to flip the segment horizontally.
  final bool hflip;
  /// Whether this segment should retain its original audio.
  final bool hasAudio;

  SegmentRequest({
    required this.sourcePath,
    required this.startTime,
    required this.duration,
    required this.hflip,
    required this.hasAudio,
  });

  /// Unique identifier for this segment request, used for caching and file naming.
  String get id {
    final fullName = sourcePath.split(RegExp(r'[/\\]')).last;
    final name = fullName.contains('.') 
        ? fullName.substring(0, fullName.lastIndexOf('.')) 
        : fullName;
    final hflipVal = hflip ? 1 : 0;
    final audioVal = hasAudio ? 1 : 0;
    return 's${startTime}_d${duration}_f${hflipVal}_a${audioVal}_$name';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentRequest &&
          runtimeType == other.runtimeType &&
          sourcePath == other.sourcePath &&
          startTime == other.startTime &&
          duration == other.duration &&
          hflip == other.hflip &&
          hasAudio == other.hasAudio;

  @override
  int get hashCode =>
      sourcePath.hashCode ^
      startTime.hashCode ^
      duration.hashCode ^
      hflip.hashCode ^
      hasAudio.hashCode;
}

/// Parameters for randomized audio transformations to avoid platform detection.
/// 
/// Contains subtle adjustments to pitch, equalizer bands, and delay to 
/// "spoof" or uniquely identify the audio stream.
class AudioSpoofProfile {
  /// Pitch adjustment factor (typically near 1.0).
  final double pitchFactor;
  /// Bass gain in dB.
  final double bassGain;
  /// Mid-range gain in dB.
  final double midGain;
  /// Treble gain in dB.
  final double trebleGain;
  /// Targeted audio bitrate in kbps.
  final int audioBitrate;
  /// Small delay in milliseconds to shift the audio phase.
  final int delayMs;

  const AudioSpoofProfile({
    required this.pitchFactor,
    required this.bassGain,
    required this.midGain,
    required this.trebleGain,
    required this.audioBitrate,
    required this.delayMs,
  });

  /// Creates a profile with random variations within safe ranges.
  factory AudioSpoofProfile.random(Random random) {
    return AudioSpoofProfile(
      pitchFactor: 0.985 + random.nextDouble() * 0.03,
      bassGain: (random.nextDouble() * 3.0) - 1.5,
      midGain: (random.nextDouble() * 3.0) - 1.5,
      trebleGain: (random.nextDouble() * 3.0) - 1.5,
      audioBitrate: [96, 112, 128, 160][random.nextInt(4)],
      delayMs: 10 + random.nextInt(31), // 10–40ms
    );
  }

  /// Builds an FFmpeg audio filter chain for background/custom music.
  String toCustomAudioFilterChain({required double volume, required double pts}) {
    final pitchStr = pitchFactor.toStringAsFixed(6);
    final totalTempo = (1.0 / (pitchFactor * pts)).clamp(0.5, 2.0).toStringAsFixed(6);
    final volStr = volume.toStringAsFixed(3);
    return 'aresample=44100,'
        'atrim=start=0,'
        'asetrate=44100*$pitchStr,'
        'atempo=$totalTempo,'
        'equalizer=f=80:width_type=o:width=2:g=${bassGain.toStringAsFixed(2)},'
        'equalizer=f=1000:width_type=o:width=2:g=${midGain.toStringAsFixed(2)},'
        'equalizer=f=8000:width_type=o:width=2:g=${trebleGain.toStringAsFixed(2)},'
        'adelay=$delayMs|$delayMs,'
        'volume=$volStr,'
        'asetpts=PTS-STARTPTS,'
        'aresample=44100,aformat=channel_layouts=stereo';
  }

  /// Builds an FFmpeg audio filter chain for the original video audio.
  String toOriginalAudioFilterChain({required double volume, required double pts}) {
    final pitchStr = pitchFactor.toStringAsFixed(6);
    final totalTempo = (1.0 / (pitchFactor * pts)).clamp(0.5, 2.0).toStringAsFixed(6);
    final volStr = volume.clamp(0.0, 1.0).toStringAsFixed(3);
    return 'aresample=44100,'
        'atrim=start=0,'
        'asetrate=44100*$pitchStr,'
        'atempo=$totalTempo,'
        'equalizer=f=80:width_type=o:width=2:g=${bassGain.toStringAsFixed(2)},'
        'equalizer=f=1000:width_type=o:width=2:g=${midGain.toStringAsFixed(2)},'
        'equalizer=f=8000:width_type=o:width=2:g=${trebleGain.toStringAsFixed(2)},'
        'adelay=$delayMs|$delayMs,'
        'volume=$volStr,'
        'asetpts=PTS-STARTPTS,'
        'aresample=44100,aformat=channel_layouts=stereo';
  }
}

// ============================================================================
// Color profiles
// ============================================================================


