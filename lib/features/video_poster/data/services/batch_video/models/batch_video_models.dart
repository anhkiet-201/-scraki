import 'dart:math';

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
    final name = sourcePath.split(RegExp(r'[/\\]')).last;
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

class ColorFilterProfile {
  final String ffmpegString;
  final int type;
  const ColorFilterProfile(this.ffmpegString, this.type);

  factory ColorFilterProfile.random(Random random) {
    final type = random.nextInt(14); 
    switch (type) {
      case 0: return ColorFilterProfile('rr=1.008:gg=1.003:bb=0.993:rg=0.002:bg=0.002', type);
      case 1: return ColorFilterProfile('rr=0.992:gg=1.002:bb=1.008:rb=0.002:gb=0.002', type);
      case 2: return ColorFilterProfile('rr=1.01:gg=1.0:bb=0.99:rg=0.005:bg=0.005', type);
      case 3: return ColorFilterProfile('rr=1.005:gg=1.0:bb=0.992:rg=0.005:gb=0.005', type);
      case 4: return ColorFilterProfile('rr=1.015:gg=0.99:bb=1.005:rg=0.003:bg=0.003', type);
      case 5: return ColorFilterProfile('rr=0.99:gg=1.01:bb=0.995:rg=0.003:bg=0.003', type);
      case 6: return ColorFilterProfile('rr=1.005:gg=1.005:bb=0.99:rg=0.005', type);
      case 7: return ColorFilterProfile('rr=0.96:gg=0.99:bb=1.03:rb=0.01:gb=0.01', type);
      case 8: return ColorFilterProfile('rr=1.02:gg=0.97:bb=1.03:br=0.01:bg=0.01', type);
      case 9: return ColorFilterProfile('rr=0.99:gg=1.0:bb=0.99:rg=0.005:bg=0.005:gr=0.005:br=0.005', type);
      case 10: return ColorFilterProfile('rr=1.03:gg=1.03:bb=1.03:rg=-0.01:rb=-0.01:gr=-0.01:gb=-0.01', type);
      case 11: return ColorFilterProfile('rr=1.0:gg=1.0:bb=1.02:rg=-0.005:bg=-0.005', type);
      case 12: return ColorFilterProfile('rr=1.01:gg=1.01:bb=1.01:rg=0.01:bg=0.01:br=0.01', type);
      default:
        final neutral = 0.99 + random.nextDouble() * 0.02;
        double jitter() => (random.nextDouble() * 0.006) - 0.003;
        return ColorFilterProfile(
          'rr=${(neutral + jitter()).toStringAsFixed(3)}:'
          'rg=${((random.nextDouble() * 0.004) - 0.002).toStringAsFixed(3)}:'
          'rb=${((random.nextDouble() * 0.004) - 0.002).toStringAsFixed(3)}:'
          'gr=${((random.nextDouble() * 0.004) - 0.002).toStringAsFixed(3)}:'
          'gg=${(neutral + jitter()).toStringAsFixed(3)}:'
          'gb=${((random.nextDouble() * 0.004) - 0.002).toStringAsFixed(3)}:'
          'br=${((random.nextDouble() * 0.004) - 0.002).toStringAsFixed(3)}:'
          'bg=${((random.nextDouble() * 0.004) - 0.002).toStringAsFixed(3)}:'
          'bb=${(neutral + jitter()).toStringAsFixed(3)}',
          type,
        );
    }
  }
}

class CurvesProfile {
  final String ffmpegString;
  final int type;
  const CurvesProfile(this.ffmpegString, this.type);

  factory CurvesProfile.random(Random random) {
    final type = random.nextInt(4);
    switch (type) {
      case 0: return CurvesProfile('all=\'0/0 0.5/0.48 1/1\'', type);
      case 1: return CurvesProfile('all=\'0/0 0.5/0.5 1/1\'', type);
      case 2:
        final midB = 0.51 + random.nextDouble() * 0.02;
        final midR = 0.48 + random.nextDouble() * 0.01;
        return CurvesProfile('b=\'0/0 0.5/$midB 1/1\':r=\'0/0 0.5/$midR 1/1\'', type);
      default:
        final p = 0.01 + random.nextDouble() * 0.01;
        return CurvesProfile('all=\'0/0 0.25/${0.25-p} 0.75/${0.75+p} 1/1\'', type);
    }
  }
}

class ColorBalanceProfile {
  final String ffmpegString;
  const ColorBalanceProfile(this.ffmpegString);

  factory ColorBalanceProfile.random(Random random) {
    double r() => (random.nextDouble() * 0.04) - 0.02;
    return ColorBalanceProfile(
      'rs=${r().toStringAsFixed(3)}:gs=${r().toStringAsFixed(3)}:bs=${r().toStringAsFixed(3)}:'
      'rm=${r().toStringAsFixed(3)}:gm=${r().toStringAsFixed(3)}:bm=${r().toStringAsFixed(3)}:'
      'rh=${r().toStringAsFixed(3)}:gh=${r().toStringAsFixed(3)}:bh=${r().toStringAsFixed(3)}'
    );
  }
}
