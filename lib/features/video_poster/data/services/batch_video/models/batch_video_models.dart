import 'dart:math';

typedef GpuInfo = ({
  String name,
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



// ============================================================================
// SegmentRequest — planning data for a single video slice
// ============================================================================

class SegmentRequest {
  final String sourcePath;
  final double startTime;
  final double duration;
  final bool hflip;
  final bool hasAudio;

  SegmentRequest({
    required this.sourcePath,
    required this.startTime,
    required this.duration,
    required this.hflip,
    required this.hasAudio,
  });

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

// ============================================================================
// AudioSpoofProfile — per-video randomized audio transform params
// ============================================================================

class AudioSpoofProfile {
  final double pitchFactor;
  final double bassGain;
  final double midGain;
  final double trebleGain;
  final int audioBitrate;
  final int delayMs;

  const AudioSpoofProfile({
    required this.pitchFactor,
    required this.bassGain,
    required this.midGain,
    required this.trebleGain,
    required this.audioBitrate,
    required this.delayMs,
  });

  factory AudioSpoofProfile.random(Random random) {
    return AudioSpoofProfile(
      pitchFactor: 0.985 + random.nextDouble() * 0.03,
      bassGain: (random.nextDouble() * 3.0) - 1.5,
      midGain: (random.nextDouble() * 3.0) - 1.5,
      trebleGain: (random.nextDouble() * 3.0) - 1.5,
      audioBitrate: [96, 112, 128, 160][random.nextInt(4)],
      delayMs: 1 + random.nextInt(5),
    );
  }

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


