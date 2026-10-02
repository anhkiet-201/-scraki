import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

void main() {
  group('Anti-Detect AudioSpoofProfile Tests', () {
    test('AudioSpoofProfile generates 5-band parametric EQ, reverb, and boundary filters', () {
      final random = Random(12345);
      final profile = AudioSpoofProfile.random(random);

      expect(profile.pitchFactor, greaterThanOrEqualTo(0.965));
      expect(profile.pitchFactor, lessThanOrEqualTo(1.035));
      expect(profile.stereoSpread, greaterThanOrEqualTo(1.05));
      expect(profile.stereoSpread, lessThanOrEqualTo(1.15));

      final customChain = profile.toCustomAudioFilterChain(volume: 0.8, pts: 1.0);

      // Verify boundary filters
      expect(customChain, contains('highpass=f=45'));
      expect(customChain, contains('lowpass=f=16000'));

      // Verify all 5 equalizer bands
      expect(customChain, contains('equalizer=f=60:width_type=o:width=2:g='));
      expect(customChain, contains('equalizer=f=250:width_type=o:width=2:g='));
      expect(customChain, contains('equalizer=f=1000:width_type=o:width=2:g='));
      expect(customChain, contains('equalizer=f=3500:width_type=o:width=2:g='));
      expect(customChain, contains('equalizer=f=10000:width_type=o:width=2:g='));

      // Verify micro-reverb and stereo spread
      expect(customChain, contains('aecho=0.8:0.88:'));
      expect(customChain, contains('extrastereo=m='));
    });

    test('toOriginalAudioFilterChain generates clamped volume and complete filter sequence', () {
      const profile = AudioSpoofProfile(
        pitchFactor: 1.015,
        subBassGain: 1.5,
        lowMidGain: -1.2,
        midGain: 0.8,
        highMidGain: -0.5,
        trebleGain: 1.2,
        audioBitrate: 128,
        delayMs: 25,
        stereoSpread: 1.09,
      );

      final origChain = profile.toOriginalAudioFilterChain(volume: 0.05, pts: 1.0);

      expect(origChain, contains('volume=0.050'));
      expect(origChain, contains('equalizer=f=60:width_type=o:width=2:g=1.50'));
      expect(origChain, contains('equalizer=f=250:width_type=o:width=2:g=-1.20'));
      expect(origChain, contains('equalizer=f=1000:width_type=o:width=2:g=0.80'));
      expect(origChain, contains('equalizer=f=3500:width_type=o:width=2:g=-0.50'));
      expect(origChain, contains('equalizer=f=10000:width_type=o:width=2:g=1.20'));
      expect(origChain, contains('aecho=0.8:0.88:25:0.12'));
      expect(origChain, contains('extrastereo=m=1.09'));
    });
  });
}
