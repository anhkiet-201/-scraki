import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:scraki/features/video_poster/domain/entities/anti_reup_config.dart';

@lazySingleton
class AntiReupService {
  final _random = Random();

  /// Generates a randomized configuration within safe "anti-detection" ranges
  AntiReupConfig maximizeStealth() {
    // Speed: 1.02x to 1.08x
    final speed = 1.02 + _random.nextDouble() * 0.06;

    // Noise: 0.03 to 0.08
    final noise = 0.03 + _random.nextDouble() * 0.05;

    // Color: 0.02 to 0.07
    final color = 0.02 + _random.nextDouble() * 0.05;

    return AntiReupConfig(
      isRandomized: true,
      speedMultiplier: double.parse(speed.toStringAsFixed(3)),
      enableVisualNoise: true,
      noiseLevel: double.parse(noise.toStringAsFixed(3)),
      colorShiftIntensity: double.parse(color.toStringAsFixed(3)),
      enableAudioPitchShift: true,
      stripMetadata: true,
    );
  }

  /// Generates FFmpeg filter chain based on configuration
  /// Returns a tuple of (videoFilters, audioFilters)
  (String videoFilter, String audioFilter) generateFilters(
    AntiReupConfig config,
  ) {
    if (config.isRandomized) {
      // If randomized mode is on, we ignore the specific values in config
      // and generate new random values ON THE FLY for this export session?
      // OR we assume the config passed in is ALREADY randomized by the UI store?
      // SOLID Principle: Service should just process what is given.
      // The Store should call [maximizeStealth] to get a config, and pass it here.
      // So we just process [config] as is.
    }

    final List<String> vFilters = [];
    final List<String> aFilters = [];

    // 1. Speed Manipulation
    // Video: setpts=PTS/SPEED
    if (config.speedMultiplier != 1.0) {
      vFilters.add('setpts=PTS/${config.speedMultiplier}');
      // Audio: atempo=SPEED
      // atempo filter is limited to 0.5 to 2.0, which is fine for our range
      aFilters.add('atempo=${config.speedMultiplier}');
    }

    // 2. Visual Noise
    if (config.enableVisualNoise && config.noiseLevel > 0) {
      // noise=alls=Intensity:allf=t+u
      // Intensity is roughly 0-100 in ffmpeg usually, but let's check docs.
      // Actually noise accepts 0-100. mapping 0.0 - 1.0 to 0 - 100
      final noiseInt = (config.noiseLevel * 100).toInt().clamp(0, 100);
      if (noiseInt > 0) {
        vFilters.add('noise=alls=$noiseInt:allf=t+u');
      }
    }

    // 3. Color Shifting (Eq + Hue)
    if (config.colorShiftIntensity > 0) {
      // Randomize direction slightly if possible, but here we just use intensity
      // Contrast: 1.0 +/- intensity
      // Brightness: +/- intensity/2
      // Saturation: 1.0 + intensity
      final contrast = 1.0 + config.colorShiftIntensity;
      final brightness = config.colorShiftIntensity / 2; // subtle
      final saturation = 1.0 + (config.colorShiftIntensity * 1.5);

      vFilters.add(
        'eq=contrast=${contrast.toStringAsFixed(2)}:'
        'brightness=${brightness.toStringAsFixed(2)}:'
        'saturation=${saturation.toStringAsFixed(2)}',
      );

      // Hue shift: very subtle shift
      // h=intensity * 10 (degrees maybe?)
      final hue = config.colorShiftIntensity * 5;
      if (hue > 0) {
        vFilters.add('hue=h=${hue.toStringAsFixed(1)}');
      }
    }

    /* 
      Note: Crop/Zoom/Mirror are destructive often, so we might skip them 
      for standard "safe" anti-reup unless explicitly requested.
      For now, speed+noise+color is a very strong combo.
    */

    return (vFilters.join(','), aFilters.join(','));
  }

  /// Returns standard FFmpeg args for metadata stripping
  List<String> getMetadataStrippingArgs(AntiReupConfig config) {
    if (!config.stripMetadata) return [];
    return ['-map_metadata', '-1'];
  }
}
