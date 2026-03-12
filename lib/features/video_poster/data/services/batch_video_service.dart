import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:scraki/features/video_poster/domain/entities/custom_image_overlay.dart';

// ============================================================================
// BatchVideoService — Cross-platform Dart reimplementation of make-vid.sh
// Works on macOS & Windows by calling ffmpeg/ffprobe via dart:io Process.
// ============================================================================

/// Configuration constants matching make-vid.sh defaults.
class BatchVideoConfig {
  final int minSegmentDuration; // seconds
  final int maxSegmentDuration; // seconds
  final int minVideoDuration; // minimum source video length to be valid
  final int minFinalDuration; // seconds
  final int maxFinalDuration; // seconds
  final int outputCount;
  final String? outputDir; // null = auto-generate with timestamp
  final Uint8List? overlayBytes;
  final List<CustomImageOverlay> imageOverlays;

  const BatchVideoConfig({
    this.minSegmentDuration = 4,
    this.maxSegmentDuration = 6,
    this.minVideoDuration = 3,
    this.minFinalDuration = 30,
    this.maxFinalDuration = 40,
    this.outputCount = 10,
    this.outputDir,
    this.overlayBytes,
    this.imageOverlays = const [],
  });
}

class BatchVideoService {
  // ─── Cross-platform binaries ──────────────────────────────────────────────

  static String get _ffmpegBin => Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';

  static String get _ffprobeBin =>
      Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';

  // Track running processes for cancellation
  final List<Process> _activeProcesses = [];
  bool _cancelled = false;

  // ─── Public entry point ───────────────────────────────────────────────────

  /// Runs the full batch video creation pipeline.
  /// Yields log lines as they are produced.
  /// [onOutputDir] is called once the output directory is known.
  Stream<String> createBatchVideos({
    required List<String> sourceVideoPaths,
    required BatchVideoConfig config,
    void Function(String dir)? onOutputDir,
    void Function(String log)? onLog,
  }) async* {
    _cancelled = false;
    _activeProcesses.clear();

    // Validate ffmpeg availability
    if (!await _checkFfmpeg()) {
      yield '❌ FFmpeg chưa được cài đặt! Vui lòng cài FFmpeg trước.';
      yield '   macOS: brew install ffmpeg';
      yield '   Windows: https://ffmpeg.org/download.html';
      return;
    }

    // Build output directory name
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('T', '_')
        .substring(0, 15);
    // Get Desktop directory as default output path
    String baseOutputDir;
    if (config.outputDir != null) {
      baseOutputDir = config.outputDir!;
    } else {
      try {
        // Fallback to current directory if path_provider fails (unlikely on desktop)
        final desktopPath = await getApplicationDocumentsDirectory()
            .then(
              (dir) =>
                  '${Directory(dir.parent.path).path}${Platform.pathSeparator}Desktop',
            )
            .catchError((_) => Directory.current.path);

        // Double check if desktop exists, some OS might have different structure
        final desktopDir = Directory(desktopPath);
        if (await desktopDir.exists()) {
          baseOutputDir = desktopPath;
        } else {
          baseOutputDir = Directory.current.path;
        }
      } catch (_) {
        baseOutputDir = Directory.current.path;
      }
    }

    final outputDir =
        '$baseOutputDir${Platform.pathSeparator}output_vids_$timestamp';

    final tempDir = Directory(
      '${Directory.systemTemp.path}/scraki_segments_$timestamp',
    );
    await tempDir.create(recursive: true);

    File? overlayFile;
    if (config.overlayBytes != null) {
      yield '🖼️ Đang chuẩn bị text overlay...';
      overlayFile = File('${tempDir.path}/overlay.png');
      await overlayFile.writeAsBytes(config.overlayBytes!);
    }

    try {
      // ── Step 1: Validate inputs & Get Durations ──────────────────────────

      yield '📋 Kiểm tra video nguồn...';
      final validVideos = <String>[];
      final videoDurations = <String, int>{};

      for (final path in sourceVideoPaths) {
        if (_cancelled) return;
        final duration = await _getVideoDuration(path);
        if (duration >= config.minVideoDuration) {
          validVideos.add(path);
          videoDurations[path] = duration;
        } else {
          yield '⚠️  Bỏ qua: ${_basename(path)} (quá ngắn: ${duration}s)';
        }
      }

      if (validVideos.isEmpty) {
        yield '❌ Không có video hợp lệ để xử lý!';
        return;
      }
      yield '✅ ${validVideos.length} video hợp lệ';

      // ── Step 2: Planning (Lazy Cutting) ──────────────────────────────────
      yield '';
      yield '[1/3] Lập kế hoạch cắt video...';
      final random = Random();

      // Plan for each output video
      final videoPlans = <int, List<_SegmentRequest>>{};
      final allUniqueSegments = <_SegmentRequest>{};

      for (int i = 1; i <= config.outputCount; i++) {
        final targetDuration =
            config.minFinalDuration +
            random.nextInt(
              config.maxFinalDuration - config.minFinalDuration + 1,
            );

        final selected = <_SegmentRequest>[];
        int totalDuration = 0;
        String lastVideoPath = '';

        while (totalDuration < targetDuration && !_cancelled) {
          final sourcePath = validVideos[random.nextInt(validVideos.length)];

          // Anti-repetition (skip if same as last unless only 1 source)
          if (sourcePath == lastVideoPath && validVideos.length > 1) continue;

          final srcDur = videoDurations[sourcePath]!;
          if (srcDur < config.minSegmentDuration) continue;

          final segDur =
              config.minSegmentDuration +
              random.nextInt(
                min(config.maxSegmentDuration, srcDur) -
                    config.minSegmentDuration +
                    1,
              );

          final maxStart = srcDur - segDur;
          if (maxStart < 0) continue;
          final startTime = random.nextInt(maxStart + 1);

          final request = _SegmentRequest(
            sourcePath: sourcePath,
            startTime: startTime,
            duration: segDur,
            hflip: random.nextBool(), // 50% chance of mirror
          );

          selected.add(request);
          allUniqueSegments.add(request);
          totalDuration += segDur;
          lastVideoPath = sourcePath;
        }
        videoPlans[i] = selected;
      }

      // ── Step 3: Render unique segments ───────────────────────────────────
      yield '';
      yield '[2/3] Đang xử lý ${allUniqueSegments.length} segments (Lazy)...';

      final segmentFileMap = <_SegmentRequest, String>{};
      final activeCutTasks = <Future<void>>{};
      int completedSegments = 0;

      for (final req in allUniqueSegments) {
        if (_cancelled) break;

        while (activeCutTasks.length >= _maxConcurrentTasks) {
          await Future.any(activeCutTasks);
        }
        if (_cancelled) break;

        final outputPath = '${tempDir.path}/${req.id}.mp4';
        segmentFileMap[req] = outputPath;

        late Future<void> task;
        task =
            _runSegmentCut(
              input: req.sourcePath,
              startSeconds: req.startTime,
              duration: req.duration,
              output: outputPath,
              hflip: req.hflip,
              processName: req.id,
              onLogMsg: onLog,
            ).then((_) {
              activeCutTasks.remove(task);
              completedSegments++;
              onLog?.call(
                '_UPDATE_LAZY: Đang render segments: $completedSegments/${allUniqueSegments.length}...',
              );
            });
        activeCutTasks.add(task);
      }
      if (activeCutTasks.isNotEmpty) await Future.wait(activeCutTasks);

      if (_cancelled) {
        yield '🛑 Đã dừng.';
        return;
      }

      // ── Step 4: Create output videos ────────────────────────────────────
      yield '';
      yield '[3/3] Đang ghép ${config.outputCount} videos...';
      await Directory(outputDir).create(recursive: true);
      onOutputDir?.call(Directory(outputDir).absolute.path);

      int successCount = 0;
      final activeTasks = <Future<void>>{};
      int currentIndex = 1;

      final streamController = StreamController<String>();
      final streamPump = streamController.stream.listen(
        (log) => onLog?.call(log),
      );

      void runCreationTask(int i) {
        final plan = videoPlans[i]!;
        final segmentsToMerge = plan.map((r) => segmentFileMap[r]!).toList();

        late Future<void> taskFuture;
        taskFuture =
            _createOutputVideo(
              outputIndex: i,
              segments: segmentsToMerge,
              outputDir: outputDir,
              config: config,
              overlayFile: overlayFile,
              onProgress: (percent) {
                if (_cancelled) return;
                final p = (percent * 100).toStringAsFixed(0);
                streamController.add(
                  '_PROGRESS_VID$i: [$i/${config.outputCount}] Đang ghép video $i... $p%',
                );
              },
            ).then((result) {
              activeTasks.remove(taskFuture);
              if (!_cancelled) {
                for (final log in result.logs) {
                  streamController.add(log);
                }
                if (result.success) {
                  successCount++;
                  streamController.add(
                    '_UPDATE_VID$i [$i/${config.outputCount}] ✓ Hoàn tất video $i',
                  );
                } else {
                  streamController.add(
                    '_UPDATE_VID$i [$i/${config.outputCount}] ✗ (thất bại video $i)',
                  );
                }
              }
            });
        activeTasks.add(taskFuture);
      }

      while (currentIndex <= config.outputCount || activeTasks.isNotEmpty) {
        if (_cancelled) break;
        while (activeTasks.length >= _maxConcurrentTasks) {
          await Future.any(activeTasks);
        }
        if (_cancelled) break;
        if (currentIndex <= config.outputCount) {
          runCreationTask(currentIndex);
          currentIndex++;
        } else {
          if (activeTasks.isNotEmpty) await Future.any(activeTasks);
        }
      }
      if (activeTasks.isNotEmpty) await Future.wait(activeTasks);

      await streamController.close();
      await streamPump.cancel();

      if (_cancelled) {
        yield '🛑 Đã dừng. Hoàn thành $successCount/${config.outputCount} videos.';
      } else {
        yield '';
        yield '✅ Hoàn thành — $successCount/${config.outputCount} videos → $outputDir';
      }
    } finally {
      // Cleanup temp directory
      try {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Cancels the running batch by killing all tracked ffmpeg processes.
  void cancel() {
    _cancelled = true;
    for (final process in _activeProcesses) {
      try {
        process.kill();
      } catch (_) {}
    }
    _activeProcesses.clear();
  }

  // ─── Constants ────────────────────────────────────────────────────────────

  static final int _maxConcurrentTasks = Platform.numberOfProcessors;

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<bool> _checkFfmpeg() async {
    try {
      final result = await Process.run(_ffmpegBin, ['-version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Uses ffprobe to get video duration in integer seconds.
  Future<int> _getVideoDuration(String filePath) async {
    try {
      final result = await Process.run(_ffprobeBin, [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'default=noprint_wrappers=1:nokey=1',
        filePath,
      ]);
      final output = (result.stdout as String).trim();
      final d = double.tryParse(output) ?? 0;
      return d.round();
    } catch (_) {
      return 0;
    }
  }

  /// Runs a single ffmpeg segment cut. Returns the output path on success, null on failure.
  /// Automatically detects HDR content and applies tonemapping to ensure all segments
  /// are normalized to yuv420p + BT.709 for compatible concat.
  Future<String?> _runSegmentCut({
    required String input,
    required int startSeconds,
    required int duration,
    required String output,
    required bool hflip,
    String? processName,
    void Function(double)? onProgress,
    void Function(String)? onLogMsg,
  }) async {
    // Detect HDR to choose the right vf filter chain
    final colorInfo = await _probeVideoColor(input);
    final hdr = _isHdr(transfer: colorInfo.transfer, pixFmt: colorInfo.pixFmt);

    // Base scale/crop/fps filter common to both paths
    String baseFilter =
        'scale=1080:1920:force_original_aspect_ratio=increase,'
        'crop=1080:1920,'
        'fps=30';

    if (hflip) {
      baseFilter += ',hflip';
    }

    // HDR: convert to linear light → tonemap → BT.709
    // Requires ffmpeg built with libzimg (standard in most distros).
    // Falls back to SDR path on failure.
    final vfFilter = hdr
        ? '$baseFilter,'
              'zscale=t=linear:npl=100,'
              'format=gbrpf32le,'
              'zscale=p=bt709,'
              'tonemap=tonemap=hable:desat=0,'
              'zscale=t=bt709:m=bt709,'
              'format=yuv420p'
        : '$baseFilter,format=yuv420p';

    Future<String?> runWithFilter(String vf) async {
      try {
        final process = await Process.start(_ffmpegBin, [
          '-hide_banner',
          '-y',
          '-ss', startSeconds.toString(),
          '-i', input,
          '-t', duration.toString(),
          '-vf', vf,
          '-an', // Always remove audio for anti-reup
          // Force normalized SDR output — critical for concat compatibility
          '-pix_fmt', 'yuv420p',
          '-color_range', 'tv',
          '-colorspace', 'bt709',
          '-color_primaries', 'bt709',
          '-color_trc', 'bt709',
          '-c:v', 'libx264',
          '-preset', 'ultrafast',
          '-crf', '26',
          '-movflags', '+faststart',
          output,
        ]);
        _activeProcesses.add(process);

        final regex = RegExp(r'time=(\d{2}):(\d{2}):(\d{2}\.\d{2})');
        // Capture full stderr for error reporting
        final stderrBuf = StringBuffer();
        process.stderr.listen((data) {
          final out = String.fromCharCodes(data);
          stderrBuf.write(out);
          if (onProgress == null || _cancelled) return;
          final match = regex.firstMatch(out);
          if (match != null) {
            final h = int.parse(match.group(1)!);
            final m = int.parse(match.group(2)!);
            final s = double.parse(match.group(3)!);
            final currentSeconds = h * 3600 + m * 60 + s;
            final percent = (currentSeconds / duration).clamp(0.0, 1.0);
            onProgress(percent);
          }
        });

        final exitCode = await process.exitCode;
        _activeProcesses.remove(process);

        if (exitCode != 0 || !File(output).existsSync()) {
          // Log the last meaningful error lines from ffmpeg stderr
          final errorLines = stderrBuf
              .toString()
              .split('\n')
              .where(
                (l) => l.toLowerCase().contains('error') || l.startsWith('  '),
              )
              .take(5)
              .join('\n');
          if (errorLines.isNotEmpty) {
            onLogMsg?.call(
              '  ❌ [${processName ?? _basename(input)}] FFmpeg lỗi:\n$errorLines',
            );
          }
          return null;
        }
        return output;
      } catch (e) {
        onLogMsg?.call(
          '  ❌ [${processName ?? _basename(input)}] Exception: $e',
        );
        return null;
      }
    }

    // Attempt with preferred filter (HDR-aware if applicable)
    final result = await runWithFilter(vfFilter);

    // If HDR tonemapping failed (e.g. zscale not available), retry with
    // simple SDR fallback — colors may be clipped but video will be created.
    if (result == null && hdr) {
      onLogMsg?.call(
        '  ⚠️ [${processName ?? _basename(input)}] zscale tonemapping thất bại, thử fallback SDR...',
      );
      final fallbackFilter = '${baseFilter},format=yuv420p';
      return runWithFilter(fallbackFilter);
    }

    return result;
  }

  /// Builds a concat list, selects diverse segments, and runs ffmpeg with
  /// randomized anti-reup filters (PTS warp, brightness, contrast, noise).
  /// Returns a record containing success flag and accumulated log lines that
  /// the caller can yield through the stream BEFORE the _UPDATE_ line.
  Future<({bool success, List<String> logs})> _createOutputVideo({
    required int outputIndex,
    required List<String> segments,
    required String outputDir,
    required BatchVideoConfig config,
    void Function(double)? onProgress,
    File? overlayFile,
  }) async {
    final logs = <String>[];
    final random = Random();

    // Target duration for this output video
    // (Already handled in planning phase in createBatchVideos)
    final targetDuration =
        config.minFinalDuration +
        random.nextInt(config.maxFinalDuration - config.minFinalDuration + 1);

    if (segments.isEmpty) {
      return (success: false, logs: logs);
    }

    // Write concat list to a temp file
    final concatFile = File(
      '${Directory.systemTemp.path}/scraki_concat_${outputIndex}_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    final buffer = StringBuffer();
    for (final seg in segments) {
      // Use absolute paths; ffmpeg concat requires forward slashes even on Windows
      final absPath = File(seg).absolute.path.replaceAll('\\', '/');
      buffer.writeln("file '$absPath'");
    }
    await concatFile.writeAsString(buffer.toString());

    // ── Random anti-reup parameters ─────────────────────────────────────────
    final pts = 0.96 + random.nextDouble() * 0.08;
    final brightness = (random.nextDouble() * 0.06) - 0.03;
    final contrast = 1.0 + random.nextDouble() * 0.05;
    final noise = 1.0 + random.nextDouble() * 3.0;

    // Per-video spoof profile (device, GPS, CRF, preset, jitter id)
    final spoofProfile = _VideoSpoofProfile.random(random);

    final brightnessStr = brightness.toStringAsFixed(4);
    final contrastStr = contrast.toStringAsFixed(4);
    final noiseStr = noise.toStringAsFixed(2);
    final ptsStr = pts.toStringAsFixed(6);

    final finalOutput =
        '${Directory(outputDir).absolute.path}${Platform.pathSeparator}final_${outputIndex.toString().padLeft(3, '0')}.mp4';

    try {
      final List<String> ffmpegArgs = [
        '-hide_banner',
        '-y',
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        concatFile.path,
      ];

      // Build overlay inputs dynamically

      // 1. Text Overlay (if exists)
      if (overlayFile != null) {
        ffmpegArgs.addAll(['-loop', '1', '-i', overlayFile.absolute.path]);
      }

      // 2. Custom Images & GIFs
      for (var img in config.imageOverlays) {
        if (img.isGif) {
          ffmpegArgs.addAll([
            '-ignore_loop',
            '0',
            '-i',
            img.localPath ?? img.imageUrl,
          ]);
        } else {
          ffmpegArgs.addAll([
            '-loop',
            '1',
            '-i',
            img.localPath ?? img.imageUrl,
          ]);
        }
      }

      // 4. Add silent audio source with tiny noise to force bitrate
      ffmpegArgs.addAll([
        '-f',
        'lavfi',
        '-i',
        'anoisesrc=d=60:c=white:a=0.001:r=44100', // Produces mono noise
      ]);

      // 3. Build complex filter
      final hasOverlays =
          overlayFile != null || config.imageOverlays.isNotEmpty;

      if (hasOverlays) {
        StringBuffer filterComplex = StringBuffer();

        // Background setup
        filterComplex.write(
          '[0:v]scale=1080:1920:force_original_aspect_ratio=increase:flags=lanczos,',
        );
        filterComplex.write('crop=1080:1920,');
        filterComplex.write(
          'eq=brightness=$brightnessStr:contrast=$contrastStr,',
        );
        filterComplex.write('noise=alls=$noiseStr:allf=t,');
        filterComplex.write('setpts=${ptsStr}*PTS[bg];');

        int overlayIdx = 1;
        String lastVideoLabel = '[bg]';

        // 3a. Overlay Custom Images FIRST (Bottom layers)
        int imageInputStartIndex = (overlayFile != null) ? 2 : 1;
        for (int i = 0; i < config.imageOverlays.length; i++) {
          var imgConfig = config.imageOverlays[i];
          int currentInputIdx = imageInputStartIndex + i;

          // Convert coordinates
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

          final int targetX = (imgConfig.x * 1080 - finalW / 2).round();
          final int targetY = (imgConfig.y * 1920 - finalH / 2).round();

          String scaleLabel = '[scaled$overlayIdx]';
          String scaleFilter = '[$currentInputIdx:v]scale=$targetW:$targetH';

          if (imgConfig.rotation != 0) {
            // Apply rotation filter, transparent background, and expand bounding box
            scaleFilter +=
                ',format=rgba,rotate=${imgConfig.rotation}*PI/180:c=black@0:ow=$finalW:oh=$finalH';
          }
          filterComplex.write('$scaleFilter$scaleLabel;');

          String nextVideoLabel = '[ov$overlayIdx]';
          if (i == config.imageOverlays.length - 1 && overlayFile == null) {
            nextVideoLabel = '[outv]';
          }

          String shortestFlag = imgConfig.isGif ? ':shortest=1' : '';
          filterComplex.write(
            '$lastVideoLabel$scaleLabel'
            'overlay=$targetX:$targetY$shortestFlag$nextVideoLabel;',
          );

          lastVideoLabel = nextVideoLabel;
          overlayIdx++;
        }

        // 3b. Overlay Text LAST (Top layer)
        if (overlayFile != null) {
          int textInputIdx = 1; // Text input is always passed first via -i
          String nextVideoLabel = '[outv]';
          filterComplex.write(
            '$lastVideoLabel[$textInputIdx:v]overlay=0:0:shortest=1$nextVideoLabel;',
          );
        }

        // Remove trailing semicolon
        String fStr = filterComplex.toString();
        if (fStr.endsWith(';')) fStr = fStr.substring(0, fStr.length - 1);

        int silentAudioIdx =
            1 + (overlayFile != null ? 1 : 0) + config.imageOverlays.length;

        ffmpegArgs.addAll([
          '-filter_complex',
          fStr,
          '-map',
          '[outv]',
          '-map',
          '$silentAudioIdx:a',
          '-c:a',
          'aac',
          '-b:a',
          '128k',
          '-ac',
          '2',
          '-shortest', // Ensure audio doesn't exceed video
          '-r',
          '30', // Force 30fps to avoid 29.35fps VFR giveaways
          '-x264-params',
          'profile=high:level=4.1:bframes=0:cabac=1:8x8dct=1:ref=1',
          '-preset',
          spoofProfile.preset,
          '-crf',
          spoofProfile.crf.toString(),
          '-map_metadata',
          '-1',
          '-brand',
          'isom',
          '-metadata',
          'major_brand=isom',
          '-metadata',
          'minor_version=512',
          '-metadata',
          'compatible_brands=isomiso2avc1mp41',
          '-metadata:s:v:0',
          'handler_name=VideoHandler',
          '-metadata:s:v:0',
          'vendor_id=[0][0][0][0]',
          '-metadata:s:a:0',
          'handler_name=SoundHandler',
          '-metadata:s:a:0',
          'vendor_id=[0][0][0][0]',
          ...spoofProfile.toFfmpegMetadataArgs(),
          '-movflags',
          '+faststart+use_metadata_tags',
          finalOutput,
        ]);
      } else {
        int silentAudioIdx = 1; // Only concat and silent audio

        ffmpegArgs.addAll([
          '-vf',
          'scale=1080:1920:force_original_aspect_ratio=increase:flags=lanczos,'
              'crop=1080:1920,'
              'eq=brightness=$brightnessStr:contrast=$contrastStr,'
              'noise=alls=$noiseStr:allf=t,'
              'setpts=${ptsStr}*PTS',
          '-map',
          '0:v',
          '-map',
          '$silentAudioIdx:a',
          '-c:a',
          'aac',
          '-ac',
          '2',
          '-b:a',
          '128k',
          '-shortest',
          '-r',
          '30',
          '-c:v',
          'libx264',
          '-x264-params',
          'profile=high:level=4.1:bframes=0:cabac=1:8x8dct=1:ref=1',
          '-preset',
          spoofProfile.preset,
          '-crf',
          spoofProfile.crf.toString(),
          '-map_metadata',
          '-1',
          '-brand',
          'isom',
          '-metadata',
          'major_brand=isom',
          '-metadata',
          'minor_version=512',
          '-metadata',
          'compatible_brands=isomiso2avc1mp41',
          '-metadata:s:v:0',
          'handler_name=VideoHandler',
          '-metadata:s:v:0',
          'vendor_id=[0][0][0][0]',
          '-metadata:s:a:0',
          'handler_name=SoundHandler',
          '-metadata:s:a:0',
          'vendor_id=[0][0][0][0]',
          ...spoofProfile.toFfmpegMetadataArgs(),
          '-movflags',
          '+faststart+use_metadata_tags',
          finalOutput,
        ]);
      }

      final process = await Process.start(_ffmpegBin, ffmpegArgs);
      _activeProcesses.add(process);

      // Collect stderr for progress tracking AND error reporting
      final regex = RegExp(r'time=(\d{2}):(\d{2}):(\d{2}\.\d{2})');
      final stderrBuf = StringBuffer();
      process.stderr.listen((data) {
        final out = String.fromCharCodes(data);
        stderrBuf.write(out);
        if (onProgress == null || _cancelled) return;
        final match = regex.firstMatch(out);
        if (match != null) {
          final h = int.parse(match.group(1)!);
          final m = int.parse(match.group(2)!);
          final s = double.parse(match.group(3)!);
          final currentSeconds = h * 3600 + m * 60 + s;
          final percent = (currentSeconds / targetDuration).clamp(0.0, 1.0);
          onProgress(percent);
        }
      });

      final exitCode = await process.exitCode;
      _activeProcesses.remove(process);

      final success = exitCode == 0 && File(finalOutput).existsSync();
      if (!success) {
        final errorLines = stderrBuf
            .toString()
            .split('\n')
            .where(
              (l) =>
                  l.isNotEmpty &&
                  !l.startsWith('frame=') &&
                  !l.startsWith('fps=') &&
                  !l.startsWith('size=') &&
                  !l.trim().startsWith('time=') &&
                  !l.trim().startsWith('speed='),
            )
            .join('\n');
        final msg =
            '  ❌ Video $outputIndex thất bại (exit=$exitCode)'
            '${errorLines.isNotEmpty ? ':\n$errorLines' : '.'}';
        debugPrint('[BatchVideo] $msg');
        logs.add(msg);
      }
      return (success: success, logs: logs);
    } catch (e, st) {
      debugPrint('[BatchVideo] Video $outputIndex exception: $e\n$st');
      logs.add('  ❌ Video $outputIndex exception: $e\n$st');
      return (success: false, logs: logs);
    } finally {
      try {
        await concatFile.delete();
      } catch (_) {}
    }
  }

  /// Cross-platform basename (last path component after / or \).
  String _basename(String path) {
    return path.split(RegExp(r'[/\\]')).last;
  }

  /// Uses ffprobe to read color_transfer, color_primaries and pix_fmt
  /// from the first video stream. Returns empty strings on error.
  Future<({String transfer, String primaries, String pixFmt})> _probeVideoColor(
    String path,
  ) async {
    try {
      final result = await Process.run(_ffprobeBin, [
        '-v',
        'error',
        '-select_streams',
        'v:0',
        '-show_entries',
        'stream=color_transfer,color_primaries,pix_fmt',
        '-of',
        'default=noprint_wrappers=1:nokey=0',
        path,
      ]);
      final out = (result.stdout as String);
      String transfer = '';
      String primaries = '';
      String pixFmt = '';
      for (final line in out.split('\n')) {
        if (line.startsWith('color_transfer=')) {
          transfer = line.split('=').last.trim();
        } else if (line.startsWith('color_primaries=')) {
          primaries = line.split('=').last.trim();
        } else if (line.startsWith('pix_fmt=')) {
          pixFmt = line.split('=').last.trim();
        }
      }
      return (transfer: transfer, primaries: primaries, pixFmt: pixFmt);
    } catch (_) {
      return (transfer: '', primaries: '', pixFmt: '');
    }
  }

  /// Returns true when the video uses an HDR transfer function (PQ / HLG)
  /// or a high-bit-depth pixel format (10/12-bit). Both require tonemapping
  /// before encoding to H.264 yuv420p.
  bool _isHdr({required String transfer, required String pixFmt}) {
    // PQ (HDR10, Dolby Vision), HLG, SMPTE 428
    const hdrTransfers = {'smpte2084', 'arib-std-b67', 'smpte428'};
    final hdrTransfer = hdrTransfers.contains(transfer);
    // 10-bit or 12-bit pixel formats exported by HEVC/AV1 cameras
    final hdrPixFmt =
        pixFmt.contains('p10') ||
        pixFmt.contains('p12') ||
        pixFmt.contains('10le') ||
        pixFmt.contains('10be');
    return hdrTransfer || hdrPixFmt;
  }
}

// ============================================================================
// _SegmentRequest — planning data for a single video slice
// ============================================================================

class _SegmentRequest {
  final String sourcePath;
  final int startTime;
  final int duration;
  final bool hflip;

  _SegmentRequest({
    required this.sourcePath,
    required this.startTime,
    required this.duration,
    required this.hflip,
  });

  String get id {
    final name = sourcePath.split(RegExp(r'[/\\]')).last;
    return 's${startTime}_d${duration}_f${hflip ? 1 : 0}_$name';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SegmentRequest &&
          runtimeType == other.runtimeType &&
          sourcePath == other.sourcePath &&
          startTime == other.startTime &&
          duration == other.duration &&
          hflip == other.hflip;

  @override
  int get hashCode =>
      sourcePath.hashCode ^
      startTime.hashCode ^
      duration.hashCode ^
      hflip.hashCode;
}

// ============================================================================
// _VideoSpoofProfile — per-video randomized metadata to avoid batch detection
// ============================================================================

/// Encapsulates all per-video spoofing parameters.
/// Call [_VideoSpoofProfile.random] to generate a fresh profile for each output.
class _VideoSpoofProfile {
  static const _devices = [
    (model: 'iPhone 13', ios: '15.6'),
    (model: 'iPhone 13 Pro', ios: '15.7.1'),
    (model: 'iPhone 14', ios: '16.3'),
    (model: 'iPhone 14 Pro Max', ios: '16.6'),
    (model: 'iPhone 15', ios: '17.0'),
    (model: 'iPhone 15 Pro Max', ios: '17.2'),
  ];

  static const _presets = ['ultrafast', 'superfast', 'veryfast'];

  /// GPS bounding box: TP.HCM + Bình Dương
  static const _latMin = 10.65;
  static const _latMax = 11.30;
  static const _lonMin = 106.55;
  static const _lonMax = 107.00;

  final String model;
  final String iosVersion;
  final String creationTime;
  final String gpsIso6709;
  final int crf;
  final String preset;
  final String jitterId; // file-size jitter
  final String videoId; // UUID for CapCut

  const _VideoSpoofProfile({
    required this.model,
    required this.iosVersion,
    required this.creationTime,
    required this.gpsIso6709,
    required this.crf,
    required this.preset,
    required this.jitterId,
    required this.videoId,
  });

  factory _VideoSpoofProfile.random(Random random) {
    final device = _devices[random.nextInt(_devices.length)];

    // Random timestamp trong 30 ngày qua
    final daysAgo = random.nextInt(30);
    final hoursAgo = random.nextInt(24);
    final minutesAgo = random.nextInt(60);
    final recordedTime = DateTime.now().toUtc().subtract(
      Duration(days: daysAgo, hours: hoursAgo, minutes: minutesAgo),
    );
    final recordedAt =
        recordedTime.toUtc().toIso8601String().split('.').first + '.000000Z';

    // GPS ngẫu nhiên trong vùng TP.HCM + Bình Dương
    final lat = _latMin + random.nextDouble() * (_latMax - _latMin);
    final lon = _lonMin + random.nextDouble() * (_lonMax - _lonMin);
    // ISO 6709 format: +10.8234+106.7183+0/
    final latSign = lat >= 0 ? '+' : '-';
    final lonSign = lon >= 0 ? '+' : '-';
    final gps =
        '$latSign${lat.abs().toStringAsFixed(4)}'
        '$lonSign${lon.abs().toStringAsFixed(4)}'
        '+0/';

    // Random CRF 23–28
    final crf = 23 + random.nextInt(6);

    // Random preset
    final preset = _presets[random.nextInt(_presets.length)];

    // 8-char hex jitter id
    final jitterId = List.generate(
      8,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();

    // Simple UUID v4 generator
    String genUuid() {
      final r = Random();
      return List.generate(36, (i) {
        if (i == 8 || i == 13 || i == 18 || i == 23) return '-';
        if (i == 14) return '4';
        final res = r.nextInt(16);
        if (i == 19) return (res & 0x3 | 0x8).toRadixString(16);
        return res.toRadixString(16);
      }).join();
    }

    return _VideoSpoofProfile(
      model: device.model,
      iosVersion: device.ios,
      creationTime: recordedAt,
      gpsIso6709: gps,
      crf: crf,
      preset: preset,
      jitterId: jitterId,
      videoId: genUuid(),
    );
  }

  String get _lvMetaInfo {
    // Escaped JSON string matching CapCut Mobile structure
    return '{"data":{"adsTemplateId":"","appVersion":"16.9.0","businessComponentId":"","businessTemplateId":"","capabilityName":"text_template,filter,transform,text_font","editType":"edit","enterFrom":"draft","exportType":"export","is_use_audio_separation":1,"launchMode":"launch","os":"android","product":"vicut","region":"VN","source_platform":"mobile_2","videoId":"$videoId"},"source_type":"vicut"}';
  }

  /// Returns ffmpeg metadata args to be added to the command.
  List<String> toFfmpegMetadataArgs() => [
    '-metadata',
    'creation_time=$creationTime',
    '-metadata',
    'Hw=1',
    '-metadata',
    'te_is_reencode=1',
    '-metadata',
    'encoder=bytevehwavc',
    '-metadata:s:v:0',
    'encoder=bytevehwavc',
    '-metadata:s:a:0',
    'encoder=bytevehwavc',
    '-metadata',
    'aigc_info={"aigc_label_type":0,"source_info":""}',
    '-metadata',
    'LvMetaInfo=$_lvMetaInfo',
    '-fflags',
    '+bitexact',
    '-flags:v',
    '+bitexact',
    '-flags:a',
    '+bitexact',
  ];
}
