import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';
import '../hardware/video_hardware_capability_resolver.dart';
import '../encoding/video_composition_engine_factory.dart';
import 'video_batch_composer.dart';

@LazySingleton(as: VideoBatchComposer)
class VideoBatchComposerImpl implements VideoBatchComposer {
  final VideoHardwareCapabilityResolver _hardwareResolver;

  VideoBatchComposerImpl(this._hardwareResolver);

  @override
  Future<ComposerResult> createOutputVideo({
    required int outputIndex,
    required List<String> segments,
    required String outputDir,
    required BatchVideoConfig config,
    required VideoBatchExecutionContext context,
    String? ambientAudioPath,
    void Function(double)? onProgress,
  }) async {
    final logs = <String>[];
    final random = Random();

    if (segments.isEmpty) return (success: false, logs: logs);

    final concatFile = File(p.join(Directory.systemTemp.path, 'scraki_concat_${outputIndex}_${DateTime.now().millisecondsSinceEpoch}.txt'));
    final buffer = StringBuffer();
    for (final seg in segments) {
      buffer.writeln("file '${File(seg).absolute.path.replaceAll('\\', '/')}'");
    }
    await concatFile.writeAsString(buffer.toString());

    final gpuInfo = await _hardwareResolver.getGpuInfo();
    final engine = VideoCompositionEngineFactory.getEngine(gpuInfo);
    
    final targetDuration = config.minFinalDuration + random.nextInt(config.maxFinalDuration - config.minFinalDuration + 1);
    final pts = 0.99 + random.nextDouble() * 0.02;
    final brightness = (random.nextDouble() * 0.04) - 0.02;
    final contrast = 1.0 + (random.nextDouble() * 0.04) - 0.02;
    final gopSize = 60 + random.nextInt(60);
    final recordedTime = DateTime.now().toUtc().subtract(Duration(days: random.nextInt(30), hours: random.nextInt(24), minutes: random.nextInt(60)));
    final creationTime = '${recordedTime.toUtc().toIso8601String().split('.').first}.000000Z';
    final audioProfile = AudioSpoofProfile.random(random);
    final double hueShift = (random.nextDouble() * 6.0) - 3.0;
    final double satFactor = 0.97 + random.nextDouble() * 0.06;
    final double vignetteAngle = pi / 100 + random.nextDouble() * (pi / 100);

    final finalOutput = '${Directory(outputDir).absolute.path}${Platform.pathSeparator}tik_final_${outputIndex.toString().padLeft(3, '0')}.mp4';
    final textOverlayFiles = <File>[];

    try {
      final List<String> ffmpegArgs = [
        '-hide_banner', '-y',
        if (gpuInfo.hwaccel != null) ...['-hwaccel', gpuInfo.hwaccel!],
        if (gpuInfo.hwaccel != null && gpuInfo.outputFormat != null) ...['-hwaccel_output_format', gpuInfo.outputFormat!],
        '-fflags', '+genpts', '-f', 'concat', '-safe', '0', '-i', concatFile.path,
      ];

      final hasCustomAudio = config.customAudioPath != null && config.customAudioPath!.isNotEmpty && File(config.customAudioPath!).existsSync();
      if (hasCustomAudio) ffmpegArgs.addAll(['-i', config.customAudioPath!]);
      final hasAmbientAudio = ambientAudioPath != null && File(ambientAudioPath).existsSync();
      if (hasAmbientAudio) ffmpegArgs.addAll(['-stream_loop', '-1', '-i', ambientAudioPath]);
      final int externalAudioCount = (hasCustomAudio ? 1 : 0) + (hasAmbientAudio ? 1 : 0);

      for (var i = 0; i < config.textOverlays.length; i++) {
        final file = File(p.join(Directory.systemTemp.path, 'scraki_text_${outputIndex}_${i}_${DateTime.now().millisecondsSinceEpoch}.png'));
        await file.writeAsBytes(config.textOverlays[i].bytes);
        textOverlayFiles.add(file);
        ffmpegArgs.addAll(['-loop', '1', '-i', file.absolute.path]);
      }
      for (var img in config.imageOverlays) {
        ffmpegArgs.addAll([img.isGif ? '-ignore_loop' : '-loop', '1', '-i', img.localPath ?? img.imageUrl]);
      }

      final StringBuffer filterComplex = StringBuffer();
      final double zoomVal = 1.02 + (random.nextDouble() * 0.02);
      final double randX = random.nextDouble();
      final double randY = random.nextDouble();

      // Stage 1: Build Background Filter via Engine
      ColorFilterProfile? cp;
      CurvesProfile? crp;
      ColorBalanceProfile? bp;
      double? gamma;
      double? gammaR, gammaG, gammaB;

      if (config.generateColorFilter) {
        cp = ColorFilterProfile.random(random);
        crp = CurvesProfile.random(random);
        bp = ColorBalanceProfile.random(random);
        gamma = 0.98 + random.nextDouble() * 0.04;
      } else {
        gammaR = 0.98 + random.nextDouble() * 0.04;
        gammaG = 0.98 + random.nextDouble() * 0.04;
        gammaB = 0.98 + random.nextDouble() * 0.04;
      }

      final bgFilter = engine.buildCompositionFilter(
        zoomVal: zoomVal,
        randX: randX,
        randY: randY,
        pts: pts,
        colorSettings: (
          colorChannelMixer: cp?.ffmpegString,
          curves: crp?.ffmpegString,
          colorBalance: bp?.ffmpegString,
          brightness: brightness,
          contrast: contrast,
          gamma: gamma,
          gammaR: gammaR,
          gammaG: gammaG,
          gammaB: gammaB,
          hueShift: hueShift,
          satFactor: satFactor,
          vignetteAngle: vignetteAngle,
        ),
        gpuInfo: gpuInfo,
      );
      
      filterComplex.write('$bgFilter[bg];');

      String lastVideoLabel = '[bg]';
      int overlayIdx = 1;
      int imageInputStartIndex = 1 + externalAudioCount + config.textOverlays.length;

      // Image Overlays
      for (int i = 0; i < config.imageOverlays.length; i++) {
        var imgConfig = config.imageOverlays[i];
        int currentInputIdx = imageInputStartIndex + i;
        final int targetW = (imgConfig.width * 1.5).round();
        final int targetH = (imgConfig.height * 1.5).round();
        int finalW = targetW;
        int finalH = targetH;
        if (imgConfig.rotation != 0) {
          final double angle = imgConfig.rotation * pi / 180;
          finalW = (targetW * cos(angle).abs() + targetH * sin(angle).abs()).round();
          finalH = (targetW * sin(angle).abs() + targetH * cos(angle).abs()).round();
        }
        final int targetX = (imgConfig.x * 1080 - finalW / 2).round();
        final int targetY = (imgConfig.y * 1920 - finalH / 2).round();
        final double oScale = 0.90 + (random.nextDouble() * 0.20);
        final double oRotate = (random.nextDouble() * 6.0) - 3.0;
        final double oBright = (random.nextDouble() * 0.08) - 0.04;
        final double oSat = 0.95 + (random.nextDouble() * 0.1);
        final int jX = random.nextInt(61) - 30;
        final int jY = random.nextInt(61) - 30;
        final int fTargetW = (targetW * oScale).round();
        final int fTargetH = (targetH * oScale).round();

        String scaleLabel = '[scaled$overlayIdx]';
        String scaleF = '[$currentInputIdx:v]scale=$fTargetW:$fTargetH,format=rgba,eq=brightness=$oBright:saturation=$oSat';
        if (imgConfig.rotation != 0 || oRotate != 0) {
          final double totalRot = imgConfig.rotation + oRotate;
          scaleF += ',rotate=$totalRot*PI/180:c=black@0:ow=$finalW:oh=$finalH';
        }
        if (imgConfig.borderWidth > 0) {
          final String borderH = _colorToHex(imgConfig.borderColor ?? Colors.white);
          scaleF += ',drawbox=c=$borderH:t=${(imgConfig.borderWidth * 1.5).round()}';
        }
        filterComplex.write('$scaleF$scaleLabel;');
        String nextVideoLabel = '[ov$overlayIdx]';
        filterComplex.write('$lastVideoLabel$scaleLabel' 'overlay=${targetX + jX}:${targetY + jY}:enable=\'between(t,${imgConfig.startTime},${imgConfig.endTime ?? 99999})\'${imgConfig.isGif ? ":shortest=1" : ""}$nextVideoLabel;');
        lastVideoLabel = nextVideoLabel;
        overlayIdx++;
      }

      // Text Overlays
      for (int i = 0; i < config.textOverlays.length; i++) {
        final overlay = config.textOverlays[i];
        int textInputIdx = 1 + externalAudioCount + i;
        if (!overlay.isAnimated) {
          final int tJX = random.nextInt(51) - 25;
          final int tJY = random.nextInt(51) - 25;
          final double tOpacity = 0.90 + (random.nextDouble() * 0.10);
          final double tRotate = (random.nextDouble() * 3.0) - 1.5;
          final double tScale = 0.97 + (random.nextDouble() * 0.06);
          String label = '[static_aocr$i]';
          filterComplex.write('[$textInputIdx:v]scale=iw*$tScale:-1,format=rgba,rotate=$tRotate*PI/180:c=black@0,colorchannelmixer=aa=$tOpacity$label;');
          final nextVideoLabel = '[ov$overlayIdx]';
          filterComplex.write('$lastVideoLabel$label' 'overlay=x=\'$tJX+1.0*sin(2*PI*n/15)\':y=\'$tJY+1.0*cos(2*PI*n/15)\':enable=\'between(t,${overlay.startTime},${overlay.endTime ?? 99999})\':shortest=1$nextVideoLabel;');
          lastVideoLabel = nextVideoLabel;
          overlayIdx++;
        } else {
          final int tW = (overlay.width * 1.5).round();
          final int tH = (overlay.height * 1.5).round();
          int fW = tW; int fH = tH;
          if (overlay.rotation != 0) {
            final double a = overlay.rotation * pi / 180;
            fW = (tW * cos(a).abs() + tH * sin(a).abs()).round();
            fH = (tW * sin(a).abs() + tH * cos(a).abs()).round();
          }
          final int centerX = (overlay.x * 1080).round();
          final int centerY = (overlay.y * 1920).round();
          final int tX = centerX - (fW ~/ 2);
          final int tY = centerY - (fH ~/ 2);
          String fBlock = '[$textInputIdx:v]scale=$tW:$tH,format=rgba';
          if (overlay.rotation != 0) fBlock += ',rotate=${overlay.rotation}*PI/180:c=black@0:ow=$fW:oh=$fH';
          final start = overlay.startTime; final end = overlay.endTime ?? 40.0;
          final totalDur = (end - start).abs();
          String xE = '$tX'; String yE = '$tY'; String sE = '1.0';
          if (overlay.animationInType != 'none') {
            final dIn = totalDur * overlay.animationInDuration;
            if (overlay.animationInType == 'fade') fBlock += ',fade=t=in:st=$start:d=$dIn:alpha=1';
            else if (overlay.animationInType == 'slideUp') yE = 'if(lt(t,${start+dIn}),$tY+75-75*(t-$start)/$dIn,$yE)';
            else if (overlay.animationInType == 'slideDown') yE = 'if(lt(t,${start+dIn}),$tY-75+75*(t-$start)/$dIn,$yE)';
            else if (overlay.animationInType == 'slideLeft') xE = 'if(lt(t,${start+dIn}),$tX+75-75*(t-$start)/$dIn,$xE)';
            else if (overlay.animationInType == 'slideRight') xE = 'if(lt(t,${start+dIn}),$tX-75+75*(t-$start)/$dIn,$xE)';
            else if (overlay.animationInType == 'zoom') {
              sE = 'if(lt(t,${start+dIn}),(t-$start)/$dIn,$sE)';
              fBlock += ',fade=t=in:st=$start:d=$dIn:alpha=1';
            }
          }
          if (overlay.animationOutType != 'none' && totalDur > 0) {
            final dOut = totalDur * overlay.animationOutDuration; final stOut = end - dOut;
            if (overlay.animationOutType == 'fade') fBlock += ',fade=t=out:st=$stOut:d=$dOut:alpha=1';
            else if (overlay.animationOutType == 'slideUp') yE = 'if(gt(t,$stOut),$tY-75*(t-$stOut)/$dOut,$yE)';
            else if (overlay.animationOutType == 'slideDown') yE = 'if(gt(t,$stOut),$tY+75*(t-$stOut)/$dOut,$yE)';
            else if (overlay.animationOutType == 'slideLeft') xE = 'if(gt(t,$stOut),$tX-75*(t-$stOut)/$dOut,$xE)';
            else if (overlay.animationOutType == 'slideRight') xE = 'if(gt(t,$stOut),$tX+75*(t-$stOut)/$dOut,$xE)';
            else if (overlay.animationOutType == 'zoom') {
              sE = 'if(gt(t,$stOut),1.0-(t-$stOut)/$dOut,$sE)';
              fBlock += ',fade=t=out:st=$stOut:d=$dOut:alpha=1';
            }
          }
          if (sE != '1.0') {
            fBlock += ",scale='bitand(iw*$sE,-2)':'bitand(ih*$sE,-2)':eval=frame";
            xE = '$centerX-w/2'; yE = '$centerY-h/2';
          }
          String label = '[anim_aocr$i]';
          filterComplex.write('$fBlock$label;');
          final nextVideoLabel = '[ov$overlayIdx]';
          filterComplex.write('$lastVideoLabel$label' 'overlay=x=\'$xE+1.0*sin(2*PI*n/20)\':y=\'$yE+1.0*cos(2*PI*n/20)\':enable=\'between(t,$start,$end)\':shortest=1$nextVideoLabel;');
          lastVideoLabel = nextVideoLabel;
          overlayIdx++;
        }
      }

      // Audio mix
      if (hasCustomAudio) {
        filterComplex.write('[0:a]${audioProfile.toOriginalAudioFilterChain(volume: 0.25, pts: pts)}[orig_a];');
        filterComplex.write('[1:a]${audioProfile.toCustomAudioFilterChain(volume: config.customAudioVolume.clamp(0.0, 1.0), pts: pts)}[music_a];');
      } else {
        filterComplex.write('[0:a]${audioProfile.toOriginalAudioFilterChain(volume: 0.05, pts: pts)}[orig_a];');
      }
      String mixLabels = '[orig_a]';
      int mixInputs = 1;
      if (hasCustomAudio) { mixInputs++; mixLabels += '[music_a]'; }
      if (hasAmbientAudio) {
        mixInputs++;
        final ambientInputIdx = hasCustomAudio ? 2 : 1;
        filterComplex.write('[$ambientInputIdx:a]volume=${(hasCustomAudio ? 0.25 : 0.05).toStringAsFixed(3)},aresample=44100,aformat=channel_layouts=stereo[ambient_a];');
        mixLabels += '[ambient_a]';
      }
      if (mixInputs > 1) {
        filterComplex.write('${mixLabels}amix=inputs=$mixInputs:duration=first:dropout_transition=0,aresample=async=1:first_pts=0[mixed_a]');
      } else {
        filterComplex.write('[orig_a]aresample=async=1:first_pts=0[mixed_a]');
      }

      ffmpegArgs.addAll([
        '-filter_complex', filterComplex.toString(),
        '-map', lastVideoLabel, '-map', '[mixed_a]',
        '-c:a', 'aac', '-b:a', '${audioProfile.audioBitrate}k', '-r', '30',
      ]);

      ffmpegArgs.addAll(engine.getCompositionEncoderArgs(
        gpuInfo,
        bitrate: '${10 + random.nextInt(6)}M',
        maxRate: '16M',
        bufSize: '25M',
        gop: gopSize,
      ));

      ffmpegArgs.addAll([
        '-pix_fmt', engine.getPreferredPixFmt(gpuInfo),
        '-colorspace', 'bt709', '-color_trc', 'bt709', '-color_primaries', 'bt709',
        '-movflags', '+faststart+use_metadata_tags', '-metadata', 'creation_time=$creationTime', '-avoid_negative_ts', 'make_zero', '-shortest',
        finalOutput
      ]);

      return await _executeFfmpeg(ffmpegArgs, outputIndex, targetDuration, finalOutput, context, onProgress);
    } catch (e, st) {
      logs.add('  ❌ Video $outputIndex exception: $e\n$st');
      return (success: false, logs: logs);
    } finally {
      if (concatFile.existsSync()) await concatFile.delete();
      for (final f in textOverlayFiles) if (f.existsSync()) await f.delete();
    }
  }

  Future<ComposerResult> _executeFfmpeg(List<String> args, int idx, int duration, String output, VideoBatchExecutionContext context, void Function(double)? onProgress) async {
    final process = await Process.start(_hardwareResolver.ffmpegBin, args);
    context.addProcess(process);
    final regex = RegExp(r'time=(\d{2}):(\d{2}):(\d{2}\.\d{2})');
    process.stderr.listen((data) {
      final out = String.fromCharCodes(data);
      if (onProgress == null || context.cancelled) return;
      final match = regex.firstMatch(out);
      if (match != null) {
        final currentSeconds = int.parse(match.group(1)!) * 3600 + int.parse(match.group(2)!) * 60 + double.parse(match.group(3)!);
        onProgress((currentSeconds / duration).clamp(0.0, 1.0));
      }
    });
    final exitCode = await process.exitCode;
    context.removeProcess(process);
    final success = exitCode == 0 && File(output).existsSync();
    final logs = <String>[];
    if (!success) logs.add('  ❌ Video $idx thất bại (exit=$exitCode).');
    return (success: success, logs: logs);
  }

  String _colorToHex(Color color) {
    return '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
