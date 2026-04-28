import 'dart:math';

import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/common/ffmpeg_toolkit.dart';

class NvidiaToolkit extends BaseFfmpegToolkit {
  NvidiaToolkit(super.hardwareResolver);

  String get scaleFilterName => gpuInfo.scaleFilter ?? 'scale_cuda';

  @override
  String scale(int width, int height) => '$scaleFilterName=$width:$height';

  @override
  String crop(int width, int height, int x, int y) => 'crop=$width:$height:$x:$y';

  @override
  String hflip() => 'hflip';

  @override
  String adjustSpeed(double pts) => 'setpts=${pts.toStringAsFixed(6)}*N/30/TB';

  @override
  String eq({double brightness = 0.0, double contrast = 1.0, double saturation = 1.0, double gamma = 1.0}) {
    return 'eq=brightness=$brightness:contrast=$contrast:saturation=$saturation:gamma=$gamma';
  }

  @override
  String hue({double? hueShift, double? saturation}) {
    final List<String> parts = [];
    if (hueShift != null) parts.add('h=$hueShift');
    if (saturation != null) parts.add('s=$saturation');
    return 'hue=${parts.join(':')}';
  }

  @override
  String vignette(double angle) => 'vignette=angle=$angle';

  @override
  String curves(String config) => 'curves=$config';

  @override
  String colorBalance(String config) => 'colorbalance=$config';

  @override
  String colorChannelMixer(String config) => 'colorchannelmixer=$config';

  @override
  String overlay({String? x, String? y, String? enable, bool shortest = false}) {
    final List<String> parts = [];
    if (x != null) parts.add('x=$x');
    if (y != null) parts.add('y=$y');
    if (enable != null) parts.add('enable=\'$enable\'');
    if (shortest) parts.add('shortest=1');
    return 'overlay=${parts.join(':')}';
  }

  @override
  String buildOverlayChain(CompositionPlan plan, String inputLabel) {
    final sb = StringBuffer();
    final random = Random(plan.outputIndex);
    final config = plan.config;
    
    String lastLabel = inputLabel;
    int overlayIdx = 0;

    // 1. Image Overlays
    for (var i = 0; i < config.imageOverlays.length; i++) {
      final img = config.imageOverlays[i];
      if (img.localPath == null) continue;
      
      final int inputIdx = 1 + (plan.hasCustomAudio ? 1 : 0) + (plan.hasAmbientAudio ? 1 : 0) + i;
      final int targetW = (img.width * 1.5).round();
      final int targetH = (img.height * 1.5).round();
      
      final int jX = random.nextInt(21) - 10;
      final int jY = random.nextInt(21) - 10;
      final double oOpacity = 0.94 + (random.nextDouble() * 0.06);
      
      final int targetX = (img.x * 1080 - targetW / 2).round();
      final int targetY = (img.y * 1920 - targetH / 2).round();

      // Nvidia: Scale to target size
      String scaleF = '[$inputIdx:v]${scale(targetW, targetH)},format=rgba,colorchannelmixer=aa=$oOpacity';
      if (img.rotation != 0) {
        scaleF += ',rotate=${img.rotation}*PI/180:c=black@0:ow=$targetW:oh=$targetH';
      }
      
      final String label = '[img_ov$i]';
      sb.write('$scaleF$label;');
      
      final String nextLabel = '[v_ov${overlayIdx++}]';
      sb.write('$lastLabel$label' '${overlay(x: '${targetX + jX}', y: '${targetY + jY}', enable: 'between(t,${img.startTime},${img.endTime ?? 99999})', shortest: img.isGif)}$nextLabel;');
      lastLabel = nextLabel;
    }

    // 2. Text Overlays
    for (var i = 0; i < plan.textOverlayPaths.length; i++) {
      final textIdx = 1 + (plan.hasCustomAudio ? 1 : 0) + (plan.hasAmbientAudio ? 1 : 0) + config.imageOverlays.length + i;
      final overlayInfo = config.textOverlays[i];
      
      String label = '[text_ov$i]';
      if (!overlayInfo.isAnimated) {
        final double tOpacity = 0.90 + (random.nextDouble() * 0.10);
        sb.write('[$textIdx:v]format=rgba,colorchannelmixer=aa=$tOpacity$label;');
        final nextLabel = '[v_ov${overlayIdx++}]';
        sb.write('$lastLabel$label' '${overlay(x: '1.0*sin(2*PI*n/15)', y: '1.0*cos(2*PI*n/15)', enable: 'between(t,${overlayInfo.startTime},${overlayInfo.endTime ?? 99999})', shortest: true)}$nextLabel;');
        lastLabel = nextLabel;
      } else {
        sb.write('[$textIdx:v]format=rgba$label;');
        final nextLabel = '[v_ov${overlayIdx++}]';
        sb.write('$lastLabel$label' '${overlay(x: '1.0*sin(2*PI*n/20)', y: '1.0*cos(2*PI*n/20)', enable: 'between(t,${overlayInfo.startTime},${overlayInfo.endTime ?? 99999})', shortest: true)}$nextLabel;');
        lastLabel = nextLabel;
      }
    }

    sb.write('$lastLabel' 'format=${gpuInfo.preferredPixFmt}');
    return sb.toString();
  }

  @override
  String buildAudioMixChain(CompositionPlan plan) {
    final params = plan.params;
    final config = plan.config;
    final sb = StringBuffer();
    
    if (plan.hasCustomAudio) {
      sb.write('[0:a]${params.audioProfile.toOriginalAudioFilterChain(volume: 0.25, pts: params.pts)}[orig_a];');
      sb.write('[1:a]${params.audioProfile.toCustomAudioFilterChain(volume: config.customAudioVolume.clamp(0.0, 1.0), pts: params.pts)}[music_a];');
    } else {
      sb.write('[0:a]${params.audioProfile.toOriginalAudioFilterChain(volume: 0.05, pts: params.pts)}[orig_a];');
    }
    
    String mixLabels = '[orig_a]';
    int mixInputs = 1;
    if (plan.hasCustomAudio) { mixInputs++; mixLabels += '[music_a]'; }
    if (plan.hasAmbientAudio) {
      mixInputs++;
      final ambientInputIdx = plan.hasCustomAudio ? 2 : 1;
      sb.write('[$ambientInputIdx:a]volume=${(plan.hasCustomAudio ? 0.25 : 0.05).toStringAsFixed(3)},aresample=44100,aformat=channel_layouts=stereo[ambient_a];');
      mixLabels += '[ambient_a]';
    }
    
    if (mixInputs > 1) {
      sb.write('${mixLabels}amix=inputs=$mixInputs:duration=first:dropout_transition=0,aresample=async=1:first_pts=0[mixed_a]');
    } else {
      sb.write('[orig_a]aresample=async=1:first_pts=0[mixed_a]');
    }
    
    return sb.toString();
  }

  @override
  String buildBaseFilter(CompositionPlan plan) {
    final params = plan.params;
    return '[0:v]${scale(1080, 1920)},${adjustSpeed(params.pts)}';
  }

  @override
  String buildColorGradingChain(CompositionPlan plan) {
    final params = plan.params;
    final List<String> filters = [];
    
    filters.add(eq(
      brightness: params.brightness,
      contrast: params.contrast,
      saturation: params.satFactor,
      gamma: params.gamma ?? 1.0,
    ));
    
    filters.add(hue(hueShift: params.hueShift));
    filters.add(vignette(params.vignetteAngle));
    
    if (params.curvesProfile != null) filters.add(curves(params.curvesProfile!.ffmpegString));
    if (params.balanceProfile != null) filters.add(colorBalance(params.balanceProfile!.ffmpegString));
    if (params.colorProfile != null) filters.add(colorChannelMixer(params.colorProfile!.ffmpegString));
    
    return filters.join(',');
  }

  @override
  String getPreferredPixelFormat() => gpuInfo.preferredPixFmt;
}
