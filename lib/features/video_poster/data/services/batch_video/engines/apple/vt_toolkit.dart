import 'dart:math';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/common/ffmpeg_toolkit.dart';

class VtToolkit extends BaseFfmpegToolkit {
  VtToolkit(super.hardwareResolver);

  String get scaleFilterName => gpuInfo.scaleFilter ?? 'scale';

  @override
  String scale(int width, int height, {double? iwScale, String? expression}) {
    if (expression != null) return '$scaleFilterName=$expression';
    if (iwScale != null) return '$scaleFilterName=iw*$iwScale:-1';
    
    if (scaleFilterName == 'zscale') {
      return 'zscale=w=$width:h=$height';
    }
    return '$scaleFilterName=$width:$height';
  }

  @override
  String getPreferredPixelFormat() => gpuInfo.preferredPixFmt;

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
      final imgConfig = config.imageOverlays[i];
      if (imgConfig.localPath == null) continue;
      
      final int currentInputIdx = 1 + (plan.hasCustomAudio ? 1 : 0) + (plan.hasAmbientAudio ? 1 : 0) + i;
      
      final int targetW = (imgConfig.width * 1.5).round();
      final int targetH = (imgConfig.height * 1.5).round();
      
      int finalW = targetW;
      int finalH = targetH;
      if (imgConfig.rotation != 0) {
        final double angle = imgConfig.rotation * pi / 180;
        finalW = (targetW * cos(angle).abs() + targetH * sin(angle).abs()).round();
        finalH = (targetW * sin(angle).abs() + targetH * cos(angle).abs()).round();
      }

      final double oScale = 0.90 + (random.nextDouble() * 0.20);
      final double oRotate = (random.nextDouble() * 6.0) - 3.0;
      final double oBright = (random.nextDouble() * 0.08) - 0.04;
      final double oSat = 0.95 + (random.nextDouble() * 0.1);
      final int jX = random.nextInt(61) - 30;
      final int jY = random.nextInt(61) - 30;
      
      final int fTargetW = (targetW * oScale).round();
      final int fTargetH = (targetH * oScale).round();
      
      final int targetX = (imgConfig.x * 1080 - finalW / 2).round();
      final int targetY = (imgConfig.y * 1920 - finalH / 2).round();

      String scaleLabel = '[scaled$overlayIdx]';
      String scaleF = '[$currentInputIdx:v]${scale(fTargetW, fTargetH)},format=rgba,${eq(brightness: oBright, saturation: oSat)}';
      
      if (imgConfig.rotation != 0 || oRotate != 0) {
        final double totalRot = imgConfig.rotation + oRotate;
        scaleF += ',${rotate(totalRot, ow: finalW, oh: finalH)}';
      }
      
      if (imgConfig.borderWidth > 0) {
        final String borderH = colorToHex(imgConfig.borderColor ?? 'white');
        scaleF += ',${drawbox(c: borderH, t: (imgConfig.borderWidth * 1.5).round())}';
      }
      
      sb.write('$scaleF$scaleLabel;');
      
      final String nextLabel = '[v_ov${overlayIdx++}]';
      sb.write('$lastLabel$scaleLabel' '${overlay(x: '${targetX + jX}', y: '${targetY + jY}', enable: 'between(t,${imgConfig.startTime},${imgConfig.endTime ?? 99999})', shortest: imgConfig.isGif)}$nextLabel;');
      lastLabel = nextLabel;
    }

    // 2. Text Overlays
    for (var i = 0; i < plan.textOverlayPaths.length; i++) {
      final overlayCfg = config.textOverlays[i];
      final int textInputIdx = 1 + (plan.hasCustomAudio ? 1 : 0) + (plan.hasAmbientAudio ? 1 : 0) + config.imageOverlays.length + i;
      
      if (!overlayCfg.isAnimated) {
        final int tJX = random.nextInt(51) - 25;
        final int tJY = random.nextInt(51) - 25;
        final double tOpacity = 0.90 + (random.nextDouble() * 0.10);
        final double tRotate = (random.nextDouble() * 3.0) - 1.5;
        final double tScale = 0.97 + (random.nextDouble() * 0.06);
        
        String label = '[static_txt$i]';
        sb.write('[$textInputIdx:v]${scale(0, 0, iwScale: tScale)},format=rgba,${rotate(tRotate, ow: -1)},${colorChannelMixer('aa=$tOpacity')}$label;');
        
        final nextLabel = '[v_ov${overlayIdx++}]';
        sb.write('$lastLabel$label' '${overlay(x: '$tJX+1.0*sin(2*PI*n/15)', y: '$tJY+1.0*cos(2*PI*n/15)', enable: 'between(t,${overlayCfg.startTime},${overlayCfg.endTime ?? 99999})', shortest: true)}$nextLabel;');
        lastLabel = nextLabel;
      } else {
        final int tW = (overlayCfg.width * 1.5).round();
        final int tH = (overlayCfg.height * 1.5).round();
        int fW = tW; int fH = tH;
        if (overlayCfg.rotation != 0) {
          final double a = overlayCfg.rotation * pi / 180;
          fW = (tW * cos(a).abs() + tH * sin(a).abs()).round();
          fH = (tW * sin(a).abs() + tH * cos(a).abs()).round();
        }
        
        final int centerX = (overlayCfg.x * 1080).round();
        final int centerY = (overlayCfg.y * 1920).round();
        final int tX = centerX - (fW ~/ 2);
        final int tY = centerY - (fH ~/ 2);
        
        String fBlock = '[$textInputIdx:v]${scale(tW, tH)},format=rgba';
        if (overlayCfg.rotation != 0) fBlock += ',${rotate(overlayCfg.rotation, ow: fW, oh: fH)}';
        
        final start = overlayCfg.startTime; 
        final end = overlayCfg.endTime ?? 40.0;
        final totalDur = (end - start).abs();
        
        String xE = '$tX'; String yE = '$tY'; String sE = '1.0';
        
        if (overlayCfg.animationInType != 'none') {
          final dIn = totalDur * overlayCfg.animationInDuration;
          if (overlayCfg.animationInType == 'fade') fBlock += ',${fade(type: 'in', start: start, duration: dIn)}';
          else if (overlayCfg.animationInType == 'slideUp') yE = 'if(lt(t,${start+dIn}),$tY+75-75*(t-$start)/$dIn,$yE)';
          else if (overlayCfg.animationInType == 'slideDown') yE = 'if(lt(t,${start+dIn}),$tY-75+75*(t-$start)/$dIn,$yE)';
          else if (overlayCfg.animationInType == 'slideLeft') xE = 'if(lt(t,${start+dIn}),$tX+75-75*(t-$start)/$dIn,$xE)';
          else if (overlayCfg.animationInType == 'slideRight') xE = 'if(lt(t,${start+dIn}),$tX-75+75*(t-$start)/$dIn,$xE)';
          else if (overlayCfg.animationInType == 'zoom') {
            sE = 'if(lt(t,${start+dIn}),(t-$start)/$dIn,$sE)';
            fBlock += ',${fade(type: 'in', start: start, duration: dIn)}';
          }
        }
        
        if (overlayCfg.animationOutType != 'none' && totalDur > 0) {
          final dOut = totalDur * overlayCfg.animationOutDuration; 
          final stOut = end - dOut;
          if (overlayCfg.animationOutType == 'fade') fBlock += ',${fade(type: 'out', start: stOut, duration: dOut)}';
          else if (overlayCfg.animationOutType == 'slideUp') yE = 'if(gt(t,$stOut),$tY-75*(t-$stOut)/$dOut,$yE)';
          else if (overlayCfg.animationOutType == 'slideDown') yE = 'if(gt(t,$stOut),$tY+75*(t-$stOut)/$dOut,$yE)';
          else if (overlayCfg.animationOutType == 'slideLeft') xE = 'if(gt(t,$stOut),$tX-75*(t-$stOut)/$dOut,$xE)';
          else if (overlayCfg.animationOutType == 'slideRight') xE = 'if(gt(t,$stOut),$tX+75*(t-$stOut)/$dOut,$xE)';
          else if (overlayCfg.animationOutType == 'zoom') {
            sE = 'if(gt(t,$stOut),1.0-(t-$stOut)/$dOut,$sE)';
            fBlock += ',${fade(type: 'out', start: stOut, duration: dOut)}';
          }
        }
        
        if (sE != '1.0') {
          fBlock += ",${scale(0, 0, expression: "'bitand(iw*$sE,-2)':'bitand(ih*$sE,-2)':eval=frame")}";
          xE = '$centerX-w/2'; yE = '$centerY-h/2';
        }
        
        String label = '[anim_txt$i]';
        sb.write('$fBlock$label;');
        
        final nextLabel = '[v_ov${overlayIdx++}]';
        sb.write('$lastLabel$label' '${overlay(x: '$xE+1.0*sin(2*PI*n/20)', y: '$yE+1.0*cos(2*PI*n/20)', enable: 'between(t,$start,$end)', shortest: true)}$nextLabel;');
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

}
