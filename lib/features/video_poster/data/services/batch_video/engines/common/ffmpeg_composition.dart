import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/execution_result.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/ffmpeg_options.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/toolkit/composition.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/toolkit/video_toolkit.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';
import 'package:path/path.dart' as p;

/// Base implementation of [Composition] using standard FFmpeg logic.
///
/// This class handles the high-level orchestration of building filter chains
/// by combining various atomic filters from a [VideoToolkit]. It also manages
/// input argument generation and process execution.
class BaseFfmpegComposition<T extends VideoToolkit> implements Composition<T> {
  /// The resolver used to identify hardware capabilities and paths.
  final VideoHardwareCapabilityResolver hardwareResolver;

  /// The toolkit used to generate atomic filter strings.
  @override
  final T toolkit;

  /// Returns information about the current GPU or a fallback CPU-based profile.
  GpuInfo get gpuInfo => (
    name: 'cpu',
    encoder: 'libx264',
    hwaccel: null,
    scaleFilter: 'scale',
    outputFormat: null,
    hasZscale: false,
    hasCudaFilters: false,
    preferredPixFmt: 'yuv420p',
    maxConcurrentEncodes: 1,
  );

  BaseFfmpegComposition({
    required this.hardwareResolver,
    required this.toolkit,
  });

  /// Prepares a concat demuxer input file for multiple video segments.
  ///
  /// Writes a temporary text file containing the paths of all segments
  /// to be concatenated by FFmpeg's concat demuxer.
  @override
  void buildConcatInput(
    FfmpegInputArgs inputs,
    List<String> paths,
    List<double>? durations,
    String tempDir,
    int index,
  ) {
    final concatFile = File('$tempDir/concat_$index.txt');
    final sb = StringBuffer();
    for (int i = 0; i < paths.length; i++) {
      // Escape single quotes in file paths
      final escapedPath = paths[i].replaceAll("'", "'\\''");
      sb.writeln("file '$escapedPath'");
      if (durations != null && i < durations.length) {
        sb.writeln("duration ${durations[i].toStringAsFixed(6)}");
      }
    }
    concatFile.writeAsStringSync(sb.toString());
    inputs.addConcatInput(concatFile.absolute.path);
  }

  /// Adds individual video segments as inputs to the [inputs] builder.
  @override
  void buildIndividualInputs(FfmpegInputArgs inputs, List<String> paths) {
    for (final path in paths) {
      inputs.addInput(path);
    }
  }

  /// Executes the FFmpeg process with the provided [args].
  ///
  /// This method automatically handles large filter scripts by writing them
  /// to a temporary file and using `-filter_complex_script` to avoid
  /// command-line length limitations.
  @override
  Future<ExecutionResult> execute(
    List<String> args,
    VideoBatchExecutionContext context, {
    void Function(String)? onLog,
    void Function(double)? onProgress,
    int? targetDuration,
    Duration? timeout,
  }) async {
    final List<String> finalArgs = ['-nostdin', ...args];
    File? filterFile;
    Timer? watchdog;
    final Duration effectiveTimeout = timeout ?? const Duration(minutes: 10);
    final List<String> errorLogs = [];

    try {
      final filterIdx = finalArgs.indexOf('-filter_complex');
      if (filterIdx != -1 && finalArgs[filterIdx + 1].length > 1000) {
        final filterContent = finalArgs[filterIdx + 1];
        final tempDir = Directory.systemTemp;
        filterFile = File(
          p.join(
            tempDir.path,
            'ffmpeg_filter_${DateTime.now().millisecondsSinceEpoch}.txt',
          ),
        );
        await filterFile.writeAsString(filterContent);

        finalArgs[filterIdx] = '-filter_complex_script';
        finalArgs[filterIdx + 1] = filterFile.path;
      }

      final process = await Process.start(
        hardwareResolver.ffmpegBin,
        finalArgs,
      );
      
      if (context.cancelled) {
        process.kill();
        return ExecutionResult(
          success: false,
          logs: ['Cancelled by user immediately after start'],
        );
      }
      
      context.addProcess(process);
      
      try {
        // Watchdog logic: Khởi động ngay để bắt lỗi hang IO từ ban đầu (đọc file/network quá chậm)
        // và reset liên tục mỗi khi có dữ liệu stderr mới.
        void resetWatchdog() {
          watchdog?.cancel();
          watchdog = Timer(const Duration(seconds: 180), () {
            try {
              onLog?.call(
                '  ⚠️ Watchdog: No activity detected for 180s. Killing process...',
              );
            } catch (e) {
              debugPrint('  [FFMPEG STREAM ERROR] Watchdog onLog exception: $e');
            }
            process.kill();
          });
        }
        resetWatchdog(); // Bắt đầu đếm ngay lập tức


        final regex = RegExp(r'time=(\d{2}):(\d{2}):(\d{2}\.\d{2})');

        final stdoutSub = process.stdout.listen((data) {
          final out = String.fromCharCodes(data);
          if (out.trim().isNotEmpty) {
            debugPrint('  [FFMPEG STDOUT] $out');
          }
        });

        final stderrSub = process.stderr.listen((data) {
          resetWatchdog(); // Reset watchdog khi nhận stderr mới
          final out = String.fromCharCodes(data);
          
          try {
            if (onLog != null) onLog(out);
          } catch (e, st) {
            debugPrint('  [FFMPEG STREAM ERROR] onLog exception: $e\n$st');
          }
          
          errorLogs.add(out);

          try {
            if (onProgress != null &&
                targetDuration != null &&
                !context.cancelled) {
              final match = regex.firstMatch(out);
              if (match != null) {
                final currentSeconds =
                    int.parse(match.group(1)!) * 3600 +
                    int.parse(match.group(2)!) * 60 +
                    double.parse(match.group(3)!);
                onProgress((currentSeconds / targetDuration).clamp(0.0, 1.0));
              }
            }
          } catch (e, st) {
            debugPrint('  [FFMPEG STREAM ERROR] onProgress exception: $e\n$st');
          }
        });

        final exitCode = await process.exitCode.timeout(
          effectiveTimeout,
          onTimeout: () {
            try {
              onLog?.call(
                '  ❌ Timeout: FFmpeg execution exceeded ${effectiveTimeout.inMinutes} minutes.',
              );
            } catch (e) {
              debugPrint('  [FFMPEG STREAM ERROR] Timeout onLog exception: $e');
            }
            process.kill();
            return -999;
          },
        );

        await stderrSub.cancel();
        await stdoutSub.cancel();
        watchdog?.cancel();

        if (exitCode == 0) {
          return ExecutionResult.success(args.last);
        } else {
          final reason = exitCode == -999 ? 'Timeout' : 'Exit code $exitCode';
          final fullError = errorLogs.join().trim();
          return ExecutionResult(
            success: false,
            logs: [
              'FFmpeg failed: $reason',
              if (fullError.isNotEmpty) 'Details:\n$fullError',
            ],
          );
        }
      } finally {
        // Đảm bảo LUÔN tháo gỡ process khỏi context để tránh memory leak
        context.removeProcess(process);
      }
    } finally {
      watchdog?.cancel();
      try {
        if (filterFile != null && await filterFile.exists()) {
          await filterFile.delete();
        }
      } catch (_) {}
    }
  }

  /// Builds the audio filter chain for mixing multiple audio sources.
  ///
  /// Combines original audio, custom background music, and ambient sounds
  /// according to the [plan].
  @override
  String buildAudioMixChain(CompositionPlan plan, {int inputOffset = 1}) {
    final params = plan.params;
    final config = plan.config;
    final sb = StringBuffer();

    // Reconstruction: [0:a] -> [orig_a]
    final String sourceLabel = plan.segmentPaths.length > 1 ? '[a_concat]' : '[0:a]';
    final double origVolume = plan.hasCustomAudio ? 0.25 : 0.05;
    sb.write(
      '$sourceLabel asetpts=N/SR/TB,${params.audioProfile.toOriginalAudioFilterChain(volume: origVolume, pts: params.pts)}[orig_a];',
    );

    // Custom Audio index
    int currentIdx = inputOffset;
    if (plan.hasCustomAudio) {
      sb.write(
        '[$currentIdx:a]${params.audioProfile.toCustomAudioFilterChain(volume: config.customAudioVolume.clamp(0.0, 1.0), pts: params.pts)}[music_a];',
      );
      currentIdx++;
    }

    String mixLabels = '[orig_a]';
    int mixInputs = 1;
    if (plan.hasCustomAudio) {
      mixInputs++;
      mixLabels += '[music_a]';
    }

    // Ambient Audio
    if (plan.hasAmbientAudio) {
      mixInputs++;
      sb.write(
        '[$currentIdx:a]volume=${(plan.hasCustomAudio ? 0.25 : 0.05).toStringAsFixed(3)},aresample=44100,aformat=channel_layouts=stereo[ambient_a];',
      );
      currentIdx++;
      mixLabels += '[ambient_a]';
    }

    if (mixInputs > 1) {
      sb.write(
        '${mixLabels}amix=inputs=$mixInputs:duration=first:dropout_transition=0,aresample=async=1:first_pts=0,apad[mixed_a]',
      );
    } else {
      sb.write('[orig_a]aresample=async=1:first_pts=0,apad[mixed_a]');
    }

    return sb.toString();
  }

  /// Builds the base video filter chain (scaling, cropping, speed adjustment).
  ///
  /// Includes jitter crop and dynamic panning (Ken Burns effect) if configured.
  @override
  String buildConcatFilter(int count) {
    if (count <= 1) return '';
    final sb = StringBuffer();
    for (int i = 0; i < count; i++) {
      sb.write('[$i:v][$i:a]');
    }
    sb.write('concat=n=$count:v=1:a=1[v_concat][a_concat];');
    return sb.toString();
  }

  @override
  String buildBaseFilter(CompositionPlan plan, {String inputLabel = '[0:v]'}) {
    final params = plan.params;

    // 1. Micro Crop Jitter
    final jitterCrop =
        'crop=iw*(1-${params.cropJitterX}):ih*(1-${params.cropJitterY}):0:0';

    // 2. Dynamic Pan (Ken Burns Effect)
    final cropW = (plan.targetWidth / params.zoomVal).round();
    final cropH = (plan.targetHeight / params.zoomVal).round();
    final maxOffX = plan.targetWidth - cropW;
    final maxOffY = plan.targetHeight - cropH;

    final sx = (params.panStartX * maxOffX).round();
    final ex = (params.panEndX * maxOffX).round();
    final sy = (params.panStartY * maxOffY).round();
    final ey = (params.panEndY * maxOffY).round();

    final xExpr = '$sx+($ex-$sx)*t/${params.targetDuration}';
    final yExpr = '$sy+($ey-$sy)*t/${params.targetDuration}';
    final dynamicPan = 'crop=$cropW:$cropH:$xExpr:$yExpr';

    final String sourceLabel =
        plan.segmentPaths.length > 1 ? '[v_concat]' : inputLabel;

    // Reconstruction: sourceLabel -> [v_clean]
    return '$sourceLabel setpts=N/30/TB,fps=30[v_clean];[v_clean]$dynamicPan,$jitterCrop,${toolkit.scale(plan.targetWidth, plan.targetHeight)},${toolkit.adjustSpeed(params.pts)}';
  }

  /// Builds the color grading filter chain.
  ///
  /// Combines equalizer (eq), hue, vignette, and optional 3D LUTs.
  @override
  String buildColorGradingChain(CompositionPlan plan) {
    final params = plan.params;
    final List<String> filters = [];

    filters.add(
      toolkit.eq(
        brightness: params.brightness,
        contrast: params.contrast,
        saturation: params.satFactor,
      ),
    );

    filters.add(toolkit.hue(hueShift: params.hueShift));
    filters.add(toolkit.vignette(params.vignetteAngle));

    if (params.lutFilePath != null) {
      filters.add(toolkit.lut3d(params.lutFilePath!));
    }

    return filters.join(',');
  }

  /// Builds the overlay chain for images and text.
  ///
  /// Iterates through all configured overlays in the [plan] and generates
  /// the necessary filter labels and overlay commands.
  @override
  String buildOverlayChain(CompositionPlan plan, String inputLabel,
      {int inputOffset = 1}) {
    final sb = StringBuffer();
    final random = Random(plan.outputIndex);
    final config = plan.config;

    String lastLabel = inputLabel;
    int overlayIdx = 0;

    int currentInputCounter = inputOffset;

    // 1. Image Overlays
    for (var i = 0; i < config.imageOverlays.length; i++) {
      final imgConfig = config.imageOverlays[i];
      if (imgConfig.localPath == null) continue;

      final int currentInputIdx = currentInputCounter++;

      final int targetW = (imgConfig.width * 1.5).round();
      final int targetH = (imgConfig.height * 1.5).round();

      int finalW = targetW;
      int finalH = targetH;
      if (imgConfig.rotation != 0) {
        final double angle = imgConfig.rotation * pi / 180;
        finalW = (targetW * cos(angle).abs() + targetH * sin(angle).abs())
            .round();
        finalH = (targetW * sin(angle).abs() + targetH * cos(angle).abs())
            .round();
      }

      final double oScale = 0.90 + (random.nextDouble() * 0.20);
      final double oRotate = (random.nextDouble() * 6.0) - 3.0;
      final double oBright = (random.nextDouble() * 0.08) - 0.04;
      final double oSat = 0.95 + (random.nextDouble() * 0.1);
      final int jX = random.nextInt(61) - 30;
      final int jY = random.nextInt(61) - 30;

      int fTargetW = (targetW * oScale).round();
      int fTargetH = (targetH * oScale).round();

      // Đảm bảo kích thước chẵn cho yuva420p
      if (fTargetW % 2 != 0) fTargetW++;
      if (fTargetH % 2 != 0) fTargetH++;

      final int targetX = (imgConfig.x * plan.targetWidth - finalW / 2).round();
      final int targetY = (imgConfig.y * plan.targetHeight - finalH / 2).round();

      String scaleLabel = '[scaled$overlayIdx]';
      String scaleF =
          '[$currentInputIdx:v]${toolkit.scale(fTargetW, fTargetH)},format=yuva420p,${toolkit.eq(brightness: oBright, saturation: oSat)}';

      if (imgConfig.rotation != 0 || oRotate != 0) {
        final double totalRot = imgConfig.rotation + oRotate;
        scaleF += ',${toolkit.rotate(totalRot, ow: finalW, oh: finalH)}';
      }

      if (imgConfig.borderWidth > 0) {
        final String borderH = toolkit.colorToHex(
          imgConfig.borderColor ?? 'white',
        );
        scaleF +=
            ',${toolkit.drawbox(c: borderH, t: (imgConfig.borderWidth * 1.5).round())}';
      }

      sb.write('$scaleF$scaleLabel;');

      final String nextLabel = '[v_ov${overlayIdx++}]';
      sb.write(
        '$lastLabel$scaleLabel'
        '${toolkit.overlay(x: '${targetX + jX}', y: '${targetY + jY}', enable: 'between(t,${imgConfig.startTime},${imgConfig.endTime ?? 99999})')}$nextLabel;',
      );
      lastLabel = nextLabel;
    }

    // 2. Text Overlays
    for (var i = 0; i < plan.textOverlayPaths.length; i++) {
      final overlayCfg = config.textOverlays[i];
      final int textInputIdx = currentInputCounter++;

      if (!overlayCfg.isAnimated) {
        final int centerX = (overlayCfg.x * plan.targetWidth).round();
        final int centerY = (overlayCfg.y * plan.targetHeight).round();
        final int tW = (overlayCfg.width * 1.5).round();
        final int tH = (overlayCfg.height * 1.5).round();
        final int tX = centerX - (tW ~/ 2);
        final int tY = centerY - (tH ~/ 2);

        final int tJX = tX + random.nextInt(51) - 25;
        final int tJY = tY + random.nextInt(51) - 25;
        final double tOpacity = 0.90 + (random.nextDouble() * 0.10);
        final double tRotate = (random.nextDouble() * 3.0) - 1.5;
        final double tScale = 0.97 + (random.nextDouble() * 0.06);

        String label = '[static_txt$i]';
        sb.write(
          '[$textInputIdx:v]${toolkit.scale(0, 0, iwScale: tScale)},format=rgba,${toolkit.rotate(tRotate)},colorchannelmixer=aa=$tOpacity$label;',
        );

        final nextLabel = '[v_ov${overlayIdx++}]';
        sb.write(
          '$lastLabel$label'
          '${toolkit.overlay(x: '$tJX+1.0*sin(2*PI*n/15)', y: '$tJY+1.0*cos(2*PI*n/15)', enable: 'between(t,${overlayCfg.startTime},${overlayCfg.endTime ?? 99999})')}$nextLabel;',
        );
        lastLabel = nextLabel;
      } else {
        final int tW = (overlayCfg.width * 1.5).round();
        final int tH = (overlayCfg.height * 1.5).round();
        int fW = tW;
        int fH = tH;
        if (overlayCfg.rotation != 0) {
          final double a = overlayCfg.rotation * pi / 180;
          fW = (tW * cos(a).abs() + tH * sin(a).abs()).round();
          fH = (tW * sin(a).abs() + tH * cos(a).abs()).round();
        }

        final int centerX = (overlayCfg.x * plan.targetWidth).round();
        final int centerY = (overlayCfg.y * plan.targetHeight).round();
        final int tX = centerX - (fW ~/ 2);
        final int tY = centerY - (fH ~/ 2);

        String fBlock = '[$textInputIdx:v]${toolkit.scale(tW, tH)},format=rgba';
        if (overlayCfg.rotation != 0)
          fBlock += ',${toolkit.rotate(overlayCfg.rotation, ow: fW, oh: fH)}';

        final start = overlayCfg.startTime;
        final end = overlayCfg.endTime ?? 40.0;
        final totalDur = (end - start).abs();

        String xE = '$tX';
        String yE = '$tY';
        String sE = '1.0';

        if (overlayCfg.animationInType != 'none') {
          final dIn = totalDur * overlayCfg.animationInDuration;
          if (overlayCfg.animationInType == 'fade')
            fBlock +=
                ',${toolkit.fade(type: 'in', start: start, duration: dIn)}';
          else if (overlayCfg.animationInType == 'slideUp')
            yE = 'if(lt(t,${start + dIn}),$tY+75-75*(t-$start)/$dIn,$yE)';
          else if (overlayCfg.animationInType == 'slideDown')
            yE = 'if(lt(t,${start + dIn}),$tY-75+75*(t-$start)/$dIn,$yE)';
          else if (overlayCfg.animationInType == 'slideLeft')
            xE = 'if(lt(t,${start + dIn}),$tX+75-75*(t-$start)/$dIn,$xE)';
          else if (overlayCfg.animationInType == 'slideRight')
            xE = 'if(lt(t,${start + dIn}),$tX-75+75*(t-$start)/$dIn,$xE)';
          else if (overlayCfg.animationInType == 'zoom') {
            sE = 'if(lt(t,${start + dIn}),(t-$start)/$dIn,$sE)';
            fBlock +=
                ',${toolkit.fade(type: 'in', start: start, duration: dIn)}';
          }
        }

        if (overlayCfg.animationOutType != 'none' && totalDur > 0) {
          final dOut = totalDur * overlayCfg.animationOutDuration;
          final stOut = end - dOut;
          if (overlayCfg.animationOutType == 'fade')
            fBlock +=
                ',${toolkit.fade(type: 'out', start: stOut, duration: dOut)}';
          else if (overlayCfg.animationOutType == 'slideUp')
            yE = 'if(gt(t,$stOut),$tY-75*(t-$stOut)/$dOut,$yE)';
          else if (overlayCfg.animationOutType == 'slideDown')
            yE = 'if(gt(t,$stOut),$tY+75*(t-$stOut)/$dOut,$yE)';
          else if (overlayCfg.animationOutType == 'slideLeft')
            xE = 'if(gt(t,$stOut),$tX-75*(t-$stOut)/$dOut,$xE)';
          else if (overlayCfg.animationOutType == 'slideRight')
            xE = 'if(gt(t,$stOut),$tX+75*(t-$stOut)/$dOut,$xE)';
          else if (overlayCfg.animationOutType == 'zoom') {
            sE = 'if(gt(t,$stOut),1.0-(t-$stOut)/$dOut,$sE)';
            fBlock +=
                ',${toolkit.fade(type: 'out', start: stOut, duration: dOut)}';
          }
        }

        if (sE != '1.0') {
          fBlock += ",scale='bitand(iw*$sE,-2)':'bitand(ih*$sE,-2)':eval=frame";
          xE = '$centerX-w/2';
          yE = '$centerY-h/2';
        }

        String label = '[anim_txt$i]';
        sb.write('$fBlock$label;');

        final nextLabel = '[v_ov${overlayIdx++}]';
        sb.write(
          '$lastLabel$label'
          '${toolkit.overlay(x: '$xE+1.0*sin(2*PI*n/20)', y: '$yE+1.0*cos(2*PI*n/20)', enable: 'between(t,$start,$end)')}$nextLabel;',
        );
        lastLabel = nextLabel;
      }
    }

    sb.write(
      '$lastLabel'
      'format=${gpuInfo.preferredPixFmt}',
    );
    return sb.toString();
  }

  /// Returns the preferred pixel format for this specific hardware/engine.
  @override
  String getPreferredPixelFormat() => gpuInfo.preferredPixFmt;
}
