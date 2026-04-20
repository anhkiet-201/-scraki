import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/mixins/batch_video_gpu_mixin.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/mixins/batch_video_state_mixin.dart';
import 'package:path/path.dart' as p;

mixin BatchVideoRenderMixin on BatchVideoGpuMixin, BatchVideoStateMixin {
  Future<({bool success, List<String> logs})> createOutputVideo({
    required int outputIndex,
    required List<String> segments,
    required String outputDir,
    required BatchVideoConfig config,
    String? ambientAudioPath,
    void Function(double)? onProgress,
  }) async {
    final logs = <String>[];
    final random = Random();

    // Target duration for this output video
    final targetDuration =
        config.minFinalDuration +
        random.nextInt(config.maxFinalDuration - config.minFinalDuration + 1);

    if (segments.isEmpty) {
      return (success: false, logs: logs);
    }

    final concatFile = File(
      p.join(Directory.systemTemp.path, 'scraki_concat_${outputIndex}_${DateTime.now().millisecondsSinceEpoch}.txt'),
    );
    final buffer = StringBuffer();
    for (final seg in segments) {
      final absPath = File(seg).absolute.path.replaceAll('\\', '/');
      buffer.writeln("file '$absPath'");
    }
    await concatFile.writeAsString(buffer.toString());

    final pts = 0.99 + random.nextDouble() * 0.02;
    final brightness = (random.nextDouble() * 0.04) - 0.02;
    final contrast = 1.0 + (random.nextDouble() * 0.04) - 0.02;
    final gopSize = 60 + random.nextInt(60);

    final recordedTime = DateTime.now().toUtc().subtract(
      Duration(
        days: random.nextInt(30),
        hours: random.nextInt(24),
        minutes: random.nextInt(60),
      ),
    );
    final creationTime = '${recordedTime.toUtc().toIso8601String().split('.').first}.000000Z';

    final hasCustomAudio = config.customAudioPath != null &&
        config.customAudioPath!.isNotEmpty &&
        File(config.customAudioPath!).existsSync();
    final audioProfile = AudioSpoofProfile.random(random);
    final ptsStr = pts.toStringAsFixed(6);

    final double hueShift = (random.nextDouble() * 6.0) - 3.0;
    final double satFactor = 0.97 + random.nextDouble() * 0.06;
    final double vignetteAngle = pi / 100 + random.nextDouble() * (pi / 100);
    
    final double gammaR = 0.98 + random.nextDouble() * 0.04;
    final double gammaG = 0.98 + random.nextDouble() * 0.04;
    final double gammaB = 0.98 + random.nextDouble() * 0.04;

    ColorFilterProfile? colorProfile;
    CurvesProfile? curvesProfile;
    if (config.generateColorFilter) {
      colorProfile = ColorFilterProfile.random(random);
      curvesProfile = CurvesProfile.random(random);
    }

    final filterId = colorProfile != null ? '${colorProfile.type}_${curvesProfile?.type}' : 'none';
    final finalOutput = '${Directory(outputDir).absolute.path}${Platform.pathSeparator}tik_final_${outputIndex.toString().padLeft(3, '0')}_f$filterId.mp4';
    final textOverlayFiles = <File>[];

    try {
      final gpuInfo = await getGpuInfo();
      final isNvidia = gpuInfo.encoder == 'h264_nvenc';
      
      final List<String> ffmpegArgs = [
        '-hide_banner', '-y',
        if (isNvidia && Platform.isWindows && gpuInfo.hasCudaFilters) ...['-hwaccel', 'cuda', '-hwaccel_output_format', 'cuda']
        else if (gpuInfo.hwaccel != null) ...['-hwaccel', 'auto'],
        '-fflags', '+genpts',
        '-f', 'concat', '-safe', '0', '-i', concatFile.path,
      ];

      if (hasCustomAudio) {
        ffmpegArgs.add('-i');
        ffmpegArgs.add(config.customAudioPath!);
      }

      final hasAmbientAudio = ambientAudioPath != null && File(ambientAudioPath).existsSync();
      if (hasAmbientAudio) {
        ffmpegArgs.addAll(['-stream_loop', '-1', '-i', ambientAudioPath]);
      }

      final int externalAudioCount = (hasCustomAudio ? 1 : 0) + (hasAmbientAudio ? 1 : 0);

      for (var i = 0; i < config.textOverlays.length; i++) {
        final overlay = config.textOverlays[i];
        final file = File(p.join(Directory.systemTemp.path, 'scraki_text_${outputIndex}_${i}_${DateTime.now().millisecondsSinceEpoch}.png'));
        await file.writeAsBytes(overlay.bytes);
        textOverlayFiles.add(file);
        ffmpegArgs.addAll(['-loop', '1', '-i', file.absolute.path]);
      }

      for (var img in config.imageOverlays) {
        if (img.isGif) {
          ffmpegArgs.addAll(['-ignore_loop', '0', '-i', img.localPath ?? img.imageUrl]);
        } else {
          ffmpegArgs.addAll(['-loop', '1', '-i', img.localPath ?? img.imageUrl]);
        }
      }

      StringBuffer filterComplex = StringBuffer();
      final double zoomVal = 1.02 + (random.nextDouble() * 0.02);
      final double randX = random.nextDouble();
      final double randY = random.nextDouble();
      final hwScale = gpuInfo.scaleFilter ?? 'scale';
      
      final String downloadCmd = gpuInfo.outputFormat != null ? 'hwdownload,format=nv12,' : '';

      if (isNvidia && Platform.isWindows && gpuInfo.hasCudaFilters) {
        // High Performance Bridge: Scale in GPU, then download only for color filters
        filterComplex.write('[0:v]$hwScale=1112:1978,hwdownload,format=nv12,');
      } else if (gpuInfo.scaleFilter != null && !Platform.isMacOS && (gpuInfo.hwaccel != 'cuda' || gpuInfo.hasCudaFilters)) {
        // Support for non-Mac hardware scalers (like QSV)
        filterComplex.write('[0:v]$hwScale=1112:1978,$downloadCmd');
      } else {
        // Use software scale for macOS and fallback cases to ensure 100% stability with complex effects
        filterComplex.write('[0:v]scale=\'if(gt(iw/ih,1080/1920),-1,1080*$zoomVal)\':\'if(gt(iw/ih,1080/1920),1920*$zoomVal,-1)\':flags=bicubic,');
      }
      filterComplex.write('crop=1080:1920:(iw-1080)*$randX:(ih-1920)*$randY,');
      
      if (config.generateColorFilter && colorProfile != null && curvesProfile != null) {
        final balanceProfile = ColorBalanceProfile.random(random);
        filterComplex.write('colorchannelmixer=${colorProfile.ffmpegString},');
        filterComplex.write('curves=${curvesProfile.ffmpegString},');
        filterComplex.write('colorbalance=${balanceProfile.ffmpegString},');
        final double gammaBase = 0.98 + random.nextDouble() * 0.04;
        filterComplex.write('eq=brightness=${brightness.toStringAsFixed(4)}:contrast=${contrast.toStringAsFixed(4)}:gamma=${gammaBase.toStringAsFixed(3)},');
      } else {
        filterComplex.write('eq=brightness=${brightness.toStringAsFixed(4)}:contrast=${contrast.toStringAsFixed(4)}:gamma_r=${gammaR.toStringAsFixed(3)}:gamma_g=${gammaG.toStringAsFixed(3)}:gamma_b=${gammaB.toStringAsFixed(3)},');
      }

      filterComplex.write('hue=h=${hueShift.toStringAsFixed(2)}:s=${satFactor.toStringAsFixed(4)},');
      filterComplex.write('vignette=${vignetteAngle.toStringAsFixed(4)},');
      
      // Final pixel format conversion for NVIDIA hardware encoder compatibility (nv12)
      final String finalFormat = isNvidia ? 'format=nv12,' : '';
      filterComplex.write('${finalFormat}trim=start=0,setpts=$ptsStr*N/30/TB[bg];');

      int overlayIdx = 1;
      String lastVideoLabel = '[bg]';
      int imageInputStartIndex = 1 + externalAudioCount + config.textOverlays.length;

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
        final double overlayScale = 0.90 + (random.nextDouble() * 0.20);
        final double overlayRotate = (random.nextDouble() * 6.0) - 3.0;
        final double overlayBright = (random.nextDouble() * 0.08) - 0.04; 
        final double overlaySat = 0.95 + (random.nextDouble() * 0.1); 
        final int jX = random.nextInt(61) - 30;
        final int jY = random.nextInt(61) - 30;
        final int finalTargetW = (targetW * overlayScale).round();
        final int finalTargetH = (targetH * overlayScale).round();

        String scaleLabel = '[scaled$overlayIdx]';
        String scaleFilter = '[$currentInputIdx:v]scale=$finalTargetW:$finalTargetH,format=rgba,eq=brightness=$overlayBright:saturation=$overlaySat';

        if (imgConfig.rotation != 0 || overlayRotate != 0) {
          final double totalRotation = imgConfig.rotation + overlayRotate;
          scaleFilter += ',rotate=$totalRotation*PI/180:c=black@0:ow=$finalW:oh=$finalH';
        }
        if (imgConfig.borderWidth > 0) {
          final String borderHex = _colorToHex(imgConfig.borderColor ?? Colors.white);
          final int ffBorderW = (imgConfig.borderWidth * 1.5).round();
          scaleFilter += ',drawbox=c=$borderHex:t=$ffBorderW';
        }

        filterComplex.write('$scaleFilter$scaleLabel;');
        String enableFilter = "enable='between(t,${imgConfig.startTime},${imgConfig.endTime ?? 99999})'";
        String nextVideoLabel = '[ov$overlayIdx]';
        String shortestFlag = imgConfig.isGif ? ':shortest=1' : '';
        filterComplex.write('$lastVideoLabel$scaleLabel' 'overlay=${targetX + jX}:${targetY + jY}:$enableFilter$shortestFlag$nextVideoLabel;');
        lastVideoLabel = nextVideoLabel;
        overlayIdx++;
      }

      for (int i = 0; i < config.textOverlays.length; i++) {
        final overlay = config.textOverlays[i];
        int textInputIdx = 1 + externalAudioCount + i;
        if (!overlay.isAnimated) {
          final int textJX = random.nextInt(51) - 25;
          final int textJY = random.nextInt(51) - 25;
          final double textOpacity = 0.90 + (random.nextDouble() * 0.10);
          final double textRotate = (random.nextDouble() * 3.0) - 1.5;
          final double textScale = 0.97 + (random.nextDouble() * 0.06);
          String antiOcrLabel = '[static_aocr$i]';
          filterComplex.write('[$textInputIdx:v]scale=iw*$textScale:-1,format=rgba,rotate=$textRotate*PI/180:c=black@0,colorchannelmixer=aa=$textOpacity$antiOcrLabel;');
          String enableFilter = "enable='between(t,${overlay.startTime},${overlay.endTime ?? 99999})'";
          final nextVideoLabel = '[ov$overlayIdx]';
          final driftX = '1.0*sin(2*PI*n/15)'; 
          final driftY = '1.0*cos(2*PI*n/15)';
          filterComplex.write('$lastVideoLabel$antiOcrLabel' 'overlay=x=\'$textJX+$driftX\':y=\'$textJY+$driftY\':$enableFilter:shortest=1$nextVideoLabel;');
          lastVideoLabel = nextVideoLabel;
          overlayIdx++;
        } else {
          final int targetW = (overlay.width * 1.5).round();
          final int targetH = (overlay.height * 1.5).round();
          int finalW = targetW;
          int finalH = targetH;
          if (overlay.rotation != 0) {
            final double angle = overlay.rotation * pi / 180;
            finalW = (targetW * cos(angle).abs() + targetH * sin(angle).abs()).round();
            finalH = (targetW * sin(angle).abs() + targetH * cos(angle).abs()).round();
          }
          final int centerX = (overlay.x * 1080).round();
          final int centerY = (overlay.y * 1920).round();
          final int targetX = centerX - (finalW ~/ 2);
          final int targetY = centerY - (finalH ~/ 2);
          String filterBlock = '[$textInputIdx:v]scale=$targetW:$targetH,format=rgba';
          if (overlay.rotation != 0) filterBlock += ',rotate=${overlay.rotation}*PI/180:c=black@0:ow=$finalW:oh=$finalH';
          final start = overlay.startTime;
          final end = overlay.endTime ?? 40.0;
          final totalDur = (end - start).abs();
          String xExprIn = ''; String yExprIn = ''; String xExprOut = ''; String yExprOut = ''; String scaleExpr = '1.0';
          if (overlay.animationInType != 'none') {
            final durIn = totalDur * overlay.animationInDuration;
            if (overlay.animationInType == 'fade') filterBlock += ',fade=t=in:st=$start:d=$durIn:alpha=1';
            else if (overlay.animationInType == 'slideUp') yExprIn = '${targetY + 75} - 75*(t-$start)/$durIn';
            else if (overlay.animationInType == 'slideDown') yExprIn = '${targetY - 75} + 75*(t-$start)/$durIn';
            else if (overlay.animationInType == 'slideLeft') xExprIn = '${targetX + 75} - 75*(t-$start)/$durIn';
            else if (overlay.animationInType == 'slideRight') xExprIn = '${targetX - 75} + 75*(t-$start)/$durIn';
            else if (overlay.animationInType == 'zoom') {
              final endIn = start + durIn;
              scaleExpr = 'if(lt(t,$endIn),(t-$start)/$durIn,1.0)';
              xExprIn = '$centerX-w/2'; yExprIn = '$centerY-h/2';
              filterBlock += ',fade=t=in:st=$start:d=$durIn:alpha=1';
            }
          }
          if (overlay.animationOutType != 'none' && totalDur > 0) {
            final durOut = totalDur * overlay.animationOutDuration;
            final startOut = end - durOut;
            if (overlay.animationOutType == 'fade') filterBlock += ',fade=t=out:st=$startOut:d=$durOut:alpha=1';
            else if (overlay.animationOutType == 'slideUp') yExprOut = '$targetY-75*(t-$startOut)/$durOut';
            else if (overlay.animationOutType == 'slideDown') yExprOut = '$targetY+75*(t-$startOut)/$durOut';
            else if (overlay.animationOutType == 'slideLeft') xExprOut = '$targetX-75*(t-$startOut)/$durOut';
            else if (overlay.animationOutType == 'slideRight') xExprOut = '$targetX+75*(t-$startOut)/$durOut';
            else if (overlay.animationOutType == 'zoom') {
              scaleExpr = 'if(gt(t,$startOut),1.0-(t-$startOut)/$durOut,$scaleExpr)';
              xExprOut = '$centerX-w/2'; yExprOut = '$centerY-h/2';
              filterBlock += ',fade=t=out:st=$startOut:d=$durOut:alpha=1';
            }
          }
          if (scaleExpr != '1.0') filterBlock += ",scale='bitand(iw*$scaleExpr,-2)':'bitand(ih*$scaleExpr,-2)':eval=frame";
          String finalXExpr = '$targetX';
          if (xExprIn.isEmpty && xExprOut.isNotEmpty) finalXExpr = 'if(gt(t\\,${end - (totalDur * overlay.animationOutDuration)})\\,$xExprOut\\,$targetX)';
          else if (xExprIn.isNotEmpty && xExprOut.isEmpty) finalXExpr = 'if(lt(t\\,${start + (totalDur * overlay.animationInDuration)})\\,$xExprIn\\,$targetX)';
          else if (xExprIn.isNotEmpty && xExprOut.isNotEmpty) {
            final endIn = start + (totalDur * overlay.animationInDuration);
            final startOut = end - (totalDur * overlay.animationOutDuration);
            finalXExpr = 'if(lt(t\\,$endIn)\\,$xExprIn\\,if(gt(t\\,$startOut)\\,$xExprOut\\,$targetX))';
          }
          String finalYExpr = '$targetY';
          if (yExprIn.isEmpty && yExprOut.isNotEmpty) finalYExpr = 'if(gt(t\\,${end - (totalDur * overlay.animationOutDuration)})\\,$yExprOut\\,$targetY)';
          else if (yExprIn.isNotEmpty && yExprOut.isEmpty) finalYExpr = 'if(lt(t\\,${start + (totalDur * overlay.animationInDuration)})\\,$yExprIn\\,$targetY)';
          else if (yExprIn.isNotEmpty && yExprOut.isNotEmpty) {
            final endIn = start + (totalDur * overlay.animationInDuration);
            final startOut = end - (totalDur * overlay.animationOutDuration);
            finalYExpr = 'if(lt(t\\,$endIn)\\,$yExprIn\\,if(gt(t\\,$startOut)\\,$yExprOut\\,$targetY))';
          }
          String antiOcrAnimLabel = '[anim_aocr$i]';
          filterComplex.write('$filterBlock$antiOcrAnimLabel;');
          String nextVideoLabel = '[ov$overlayIdx]';
          final driftX = '1.0*sin(2*PI*n/20)'; final driftY = '1.0*cos(2*PI*n/20)';
          filterComplex.write('$lastVideoLabel$antiOcrAnimLabel' 'overlay=x=\'$finalXExpr+$driftX\':y=\'$finalYExpr+$driftY\':enable=\'between(t,$start,$end)\':shortest=1$nextVideoLabel;');
          lastVideoLabel = nextVideoLabel;
          overlayIdx++;
        }
      }

      String fStr = filterComplex.toString();
      String audioMapArg; int mixInputs = 1;
      if (hasCustomAudio) {
         final origChain = audioProfile.toOriginalAudioFilterChain(volume: 0.25, pts: pts);
         fStr += '[0:a]$origChain[orig_a];';
      } else {
         final origChain = audioProfile.toOriginalAudioFilterChain(volume: 0.05, pts: pts);
         fStr += '[0:a]$origChain[orig_a];';
      }
      String mixLabels = '[orig_a]';
      if (hasCustomAudio) {
        mixInputs++;
        final customVol = config.customAudioVolume.clamp(0.0, 1.0);
        final customChain = audioProfile.toCustomAudioFilterChain(volume: customVol, pts: pts);
        fStr += '[1:a]$customChain[music_a];';
        mixLabels += '[music_a]';
      }
      if (hasAmbientAudio) {
        mixInputs++;
        final ambientVol = hasCustomAudio ? 0.25 : 0.05;
        final ambientInputIdx = hasCustomAudio ? 2 : 1;
        fStr += '[$ambientInputIdx:a]volume=${ambientVol.toStringAsFixed(3)},aresample=44100,aformat=channel_layouts=stereo[ambient_a];';
        mixLabels += '[ambient_a]';
      }
      if (mixInputs > 1) {
         fStr += '${mixLabels}amix=inputs=$mixInputs:duration=first:dropout_transition=0,aresample=async=1:first_pts=0[mixed_a]';
         audioMapArg = '[mixed_a]';
      } else {
         fStr += '[orig_a]aresample=async=1:first_pts=0[final_orig_a]';
         audioMapArg = '[final_orig_a]';
      }
      if (fStr.endsWith(';')) fStr = fStr.substring(0, fStr.length - 1);

      ffmpegArgs.addAll([
        '-filter_complex', fStr, '-map', lastVideoLabel, '-map', audioMapArg,
        '-c:a', 'aac', '-b:a', '${audioProfile.audioBitrate}k', '-r', '30',
        '-c:v', gpuInfo.encoder, '-b:v', '${10 + random.nextInt(6)}M',
        '-maxrate', '16M', '-bufsize', '25M', '-pix_fmt', 'yuv420p',
        '-colorspace', 'bt709', '-color_trc', 'bt709', '-color_primaries', 'bt709',
        if (gpuInfo.encoder == 'libx264') ...['-preset', 'superfast', '-g', gopSize.toString()]
        else if (gpuInfo.encoder == 'h264_qsv') ...['-preset', 'veryfast', '-g', gopSize.toString()]
        else ...['-g', gopSize.toString()],
        '-movflags', '+faststart+use_metadata_tags', '-metadata', 'creation_time=$creationTime',
        '-avoid_negative_ts', 'make_zero', '-shortest', finalOutput,
      ]);

      final process = await Process.start(BatchVideoGpuMixin.ffmpegBin, ffmpegArgs);
      activeProcesses.add(process);
      final regex = RegExp(r'time=(\d{2}):(\d{2}):(\d{2}\.\d{2})');
      final stderrBuf = StringBuffer();
      process.stderr.listen((data) {
        final out = String.fromCharCodes(data); stderrBuf.write(out);
        if (onProgress == null || cancelled) return;
        final match = regex.firstMatch(out);
        if (match != null) {
          final h = int.parse(match.group(1)!); final m = int.parse(match.group(2)!); final s = double.parse(match.group(3)!);
          final currentSeconds = h * 3600 + m * 60 + s;
          onProgress((currentSeconds / targetDuration).clamp(0.0, 1.0));
        }
      });

      final exitCode = await process.exitCode;
      activeProcesses.remove(process);
      final success = exitCode == 0 && File(finalOutput).existsSync();
      if (!success) {
        final errorLines = stderrBuf.toString().split('\n').where((l) => l.isNotEmpty && !l.startsWith('frame=') && !l.startsWith('fps=') && !l.startsWith('size=') && !l.trim().startsWith('time=') && !l.trim().startsWith('speed=')).join('\n');
        final filterInfo = ' (Filters: filter_complex=$fStr)';
        logs.add('  ❌ Video $outputIndex thất bại (exit=$exitCode)${errorLines.isNotEmpty ? ':\n$errorLines' : '.'}\n$filterInfo');
      }
      return (success: success, logs: logs);
    } catch (e, st) {
      logs.add('  ❌ Video $outputIndex exception: $e\n$st');
      return (success: false, logs: logs);
    } finally {
      try { if (concatFile.existsSync()) await concatFile.delete(); } catch (_) {}
      for (final file in textOverlayFiles) { try { if (file.existsSync()) await file.delete(); } catch (_) {} }
    }
  }

  String _colorToHex(Color color) {
    return '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
