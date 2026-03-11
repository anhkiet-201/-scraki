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
      // ── Step 1: Validate inputs ──────────────────────────────────────────

      yield '📋 Kiểm tra video nguồn...';
      final validVideos = <String>[];
      for (final path in sourceVideoPaths) {
        if (_cancelled) return;
        final duration = await _getVideoDuration(path);
        if (duration >= config.minVideoDuration) {
          validVideos.add(path);
        } else {
          yield '⚠️  Bỏ qua: ${_basename(path)} (quá ngắn: ${duration}s)';
        }
      }

      if (validVideos.isEmpty) {
        yield '❌ Không có video hợp lệ để xử lý!';
        return;
      }
      yield '✅ ${validVideos.length} video hợp lệ';

      // ── Step 2: Cut into segments ─────────────────────────────────────────
      yield '';
      yield '[1/2] Cắt segments...';
      await tempDir.create(recursive: true);

      final segments = <String>[];
      int videoIndex = 0;

      for (final video in validVideos) {
        if (_cancelled) break;
        videoIndex++;
        final duration = await _getVideoDuration(video);
        yield '[Video $videoIndex] Đang chuẩn bị cắt...';

        final newSegs = await _cutVideoToSegments(
          video: video,
          videoIndex: videoIndex,
          duration: duration,
          config: config,
          tempDir: tempDir.path,
          onLog: (msg) {
            onLog?.call(msg);
          },
        );
        segments.addAll(newSegs);
      }

      if (_cancelled) {
        yield '🛑 Đã dừng.';
        return;
      }

      yield '   → ${segments.length} segments đã tạo ✓';

      if (segments.length < 6) {
        yield '❌ Không đủ segments (cần ≥ 6, có ${segments.length})';
        return;
      }

      // ── Step 3: Create output videos ────────────────────────────────────
      yield '';
      yield '[2/2] Tạo ${config.outputCount} videos...';
      await Directory(outputDir).create(recursive: true);
      onOutputDir?.call(Directory(outputDir).absolute.path);

      int successCount = 0;
      final activeTasks = <Future<void>>{};
      int currentIndex = 1;

      // Ensure we don't start tasks if cancelled early
      if (_cancelled) {
        yield '🛑 Đã dừng.';
        return;
      }

      // We need a way to let tasks yield logs to the stream.
      // Easiest is to accumulate them and yield them in the main isolate when futures complete/progress.
      // But StreamController is better. We'll use a local controller that pipes to the outer async*.
      final streamController = StreamController<String>();

      void runCreationTask(int i) {
        late Future<void> taskFuture;
        taskFuture =
            _createOutputVideo(
              outputIndex: i,
              segments: segments,
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

      // Helper to pump streamController events to yield
      final streamPump = streamController.stream.listen(
        (log) => onLog?.call(log),
      );

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
          if (activeTasks.isNotEmpty) {
            await Future.any(activeTasks);
          }
        }
      }

      if (activeTasks.isNotEmpty) {
        await Future.wait(activeTasks);
      }

      // Close the stream controller and wait for pump to finish
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

  /// Cuts a single source video into 4-6 second segments in parallel (max 5).
  Future<List<String>> _cutVideoToSegments({
    required String video,
    required int videoIndex,
    required int duration,
    required BatchVideoConfig config,
    required String tempDir,
    required void Function(String) onLog,
  }) async {
    final random = Random();
    final activeTasks = <Future<void>>{};
    int currentTime = 0;
    int segmentIndex = 0;
    int completedSegments = 0;
    int totalSegmentsToCut = 0;

    // First pass to determine total segments for progress tracking
    int tempTime = 0;
    while (tempTime < duration) {
      final segDuration =
          config.minSegmentDuration +
          random.nextInt(
            config.maxSegmentDuration - config.minSegmentDuration + 1,
          );
      final remaining = duration - tempTime;
      final actualDuration = min(segDuration, remaining);
      if (actualDuration < 2) break;
      totalSegmentsToCut++;
      tempTime += actualDuration;
    }

    while (currentTime < duration || activeTasks.isNotEmpty) {
      if (_cancelled) break;

      // Limit to max concurrent tasks
      while (activeTasks.length >= _maxConcurrentTasks) {
        await Future.any(activeTasks);
      }
      if (_cancelled) break;

      if (currentTime < duration) {
        // Random segment length between min and max
        final segDuration =
            config.minSegmentDuration +
            random.nextInt(
              config.maxSegmentDuration - config.minSegmentDuration + 1,
            );
        final remaining = duration - currentTime;
        final actualDuration = min(segDuration, remaining);

        // Skip segments shorter than 2s
        if (actualDuration >= 2) {
          segmentIndex++;
          final vidIdx = videoIndex.toString().padLeft(3, '0');
          final segIdx = segmentIndex.toString().padLeft(3, '0');
          final outputPath = '$tempDir/video${vidIdx}_seg$segIdx.mp4';

          final processName = 'V${vidIdx}_S$segIdx';

          late Future<void> taskFuture;
          taskFuture =
              _runSegmentCut(
                input: video,
                startSeconds: currentTime,
                duration: actualDuration,
                output: outputPath,
                processName: processName,
                onProgress: (percent) {},
                onLogMsg: onLog,
              ).then((res) {
                completedSegments++;
                activeTasks.remove(taskFuture);
                if (!_cancelled) {
                  onLog(
                    '_PROGRESS_CUT$videoIndex: Đang cắt video $videoIndex: Hoàn thành $completedSegments/$totalSegmentsToCut segment(s)...',
                  );
                }
              });

          activeTasks.add(taskFuture);
        }
        currentTime += actualDuration;
      } else {
        // If we've reached the end of the video but tasks are still running, wait for them
        if (activeTasks.isNotEmpty) {
          await Future.any(activeTasks);
        }
      }
    }

    // Wait for remaining, though logic above should handle most of it
    if (activeTasks.isNotEmpty) await Future.wait(activeTasks);

    // Clear the progress line so it stays as a completed note
    if (!_cancelled) {
      onLog(
        '_UPDATE_CUT$videoIndex [Video $videoIndex] ✓ Hoàn thành cắt $completedSegments segment(s).',
      );
    }

    final results = <String>[];
    // Collect output files in order
    final dir = Directory(tempDir);
    final vidIdx = videoIndex.toString().padLeft(3, '0');
    await for (final entity in dir.list()) {
      if (entity is File &&
          entity.path.contains('video${vidIdx}_seg') &&
          entity.path.endsWith('.mp4')) {
        results.add(entity.path);
      }
    }
    results.sort();
    return results;
  }

  /// Runs a single ffmpeg segment cut. Returns the output path on success, null on failure.
  /// Automatically detects HDR content and applies tonemapping to ensure all segments
  /// are normalized to yuv420p + BT.709 for compatible concat.
  Future<String?> _runSegmentCut({
    required String input,
    required int startSeconds,
    required int duration,
    required String output,
    String? processName,
    void Function(double)? onProgress,
    void Function(String)? onLogMsg,
  }) async {
    // Detect HDR to choose the right vf filter chain
    final colorInfo = await _probeVideoColor(input);
    final hdr = _isHdr(transfer: colorInfo.transfer, pixFmt: colorInfo.pixFmt);

    // Base scale/crop/fps filter common to both paths
    const baseFilter =
        'scale=1080:1920:force_original_aspect_ratio=increase,'
        'crop=1080:1920,'
        'fps=30';

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
          '-af', 'volume=0.05',
          // Force normalized SDR output — critical for concat compatibility
          '-pix_fmt', 'yuv420p',
          '-color_range', 'tv',
          '-colorspace', 'bt709',
          '-color_primaries', 'bt709',
          '-color_trc', 'bt709',
          '-c:v', 'libx264',
          '-preset', 'ultrafast',
          '-crf', '26',
          '-c:a', 'aac',
          '-b:a', '128k',
          '-ar', '44100',
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
    final targetDuration =
        config.minFinalDuration +
        random.nextInt(config.maxFinalDuration - config.minFinalDuration + 1);

    // Select segments until we hit target duration, avoiding adjacent same-source
    final selected = <String>[];
    int totalDuration = 0;
    String lastVideoId = '';

    // Check total distinct sources
    final uniqueSourceCount = segments
        .map(
          (s) => _basename(s).contains('_seg')
              ? _basename(s).split('_seg').first
              : _basename(s),
        )
        .toSet()
        .length;

    var availableSegments = List<String>.from(segments);
    _shuffleList(availableSegments, random);

    while (totalDuration < targetDuration && !_cancelled) {
      if (availableSegments.isEmpty) {
        break;
      }

      // Rút ngẫu nhiên từ pool segment 1 lần (sau khi shuffle)
      final seg = availableSegments.removeLast();
      if (!File(seg).existsSync()) continue;

      final basename = _basename(seg);
      final currentVideoId = basename.contains('_seg')
          ? basename.split('_seg').first
          : basename;

      // Anti-repetition check (UNLESS we only have 1 source video)
      if (currentVideoId == lastVideoId &&
          selected.isNotEmpty &&
          uniqueSourceCount > 1) {
        continue;
      }

      final segDur = await _getVideoDuration(seg);
      selected.add(seg);
      totalDuration += segDur;
      lastVideoId = currentVideoId;
    }

    if (totalDuration < targetDuration) {
      logs.add(
        '  ⚠️ Video $outputIndex: Chỉ gom được ${totalDuration}s (cần ${targetDuration}s). Thêm video gốc.',
      );
      return (success: false, logs: logs);
    }

    if (selected.isEmpty) {
      return (success: false, logs: logs);
    }

    // Write concat list to a temp file
    final concatFile = File(
      '${Directory.systemTemp.path}/scraki_concat_${outputIndex}_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    final buffer = StringBuffer();
    for (final seg in selected) {
      // Use absolute paths; ffmpeg concat requires forward slashes even on Windows
      final absPath = File(seg).absolute.path.replaceAll('\\\\', '/');
      buffer.writeln("file '$absPath'");
    }
    await concatFile.writeAsString(buffer.toString());

    // ── Random anti-reup parameters ─────────────────────────────────────────
    final pts = 0.96 + random.nextDouble() * 0.08;
    final tempo = 1.0 / pts;
    final brightness = (random.nextDouble() * 0.06) - 0.03;
    final contrast = 1.0 + random.nextDouble() * 0.05;
    final noise = 1.0 + random.nextDouble() * 3.0;

    // Per-video spoof profile (device, GPS, CRF, preset, jitter id)
    final spoofProfile = _VideoSpoofProfile.random(random);

    final brightnessStr = brightness.toStringAsFixed(4);
    final contrastStr = contrast.toStringAsFixed(4);
    final noiseStr = noise.toStringAsFixed(2);
    final ptsStr = pts.toStringAsFixed(6);
    final tempoStr = tempo.toStringAsFixed(6);

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
          final int targetX = (imgConfig.x * 1080 - targetW / 2).round();
          final int targetY = (imgConfig.y * 1920 - targetH / 2).round();

          String scaleLabel = '[scaled$overlayIdx]';
          String scaleFilter = '[$currentInputIdx:v]scale=$targetW:$targetH';

          if (imgConfig.rotation != 0) {
            // Apply rotation filter, transparent background
            scaleFilter +=
                ',format=rgba,rotate=${imgConfig.rotation}*PI/180:c=black@0';
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

        ffmpegArgs.addAll([
          '-filter_complex',
          fStr,
          '-map',
          '[outv]',
          '-map',
          '0:a?',
          '-af',
          'volume=0.05,atempo=$tempoStr',
          '-c:v',
          'libx264',
          '-preset',
          spoofProfile.preset,
          '-crf',
          spoofProfile.crf.toString(),
          '-c:a',
          'aac',
          '-b:a',
          '128k',
          '-brand',
          'qt  ',
          '-map_metadata',
          '-1',
          '-metadata:s:v:0',
          'handler_name=Core Media Video',
          '-metadata:s:a:0',
          'handler_name=Core Media Audio',
          ...spoofProfile.toFfmpegMetadataArgs(),
          '-movflags',
          '+faststart',
          finalOutput,
        ]);
      } else {
        ffmpegArgs.addAll([
          '-vf',
          'scale=1080:1920:force_original_aspect_ratio=increase:flags=lanczos,'
              'crop=1080:1920,'
              'eq=brightness=$brightnessStr:contrast=$contrastStr,'
              'noise=alls=$noiseStr:allf=t,'
              'setpts=${ptsStr}*PTS',
          '-af',
          'volume=0.05,atempo=$tempoStr',
          '-c:v',
          'libx264',
          '-preset',
          spoofProfile.preset,
          '-crf',
          spoofProfile.crf.toString(),
          '-c:a',
          'aac',
          '-b:a',
          '128k',
          '-brand',
          'qt  ',
          '-map_metadata',
          '-1',
          '-metadata:s:v:0',
          'handler_name=Core Media Video',
          '-metadata:s:a:0',
          'handler_name=Core Media Audio',
          ...spoofProfile.toFfmpegMetadataArgs(),
          '-movflags',
          '+faststart',
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

  /// Fisher-Yates in-place shuffle using Dart Random.
  void _shuffleList<T>(List<T> list, Random random) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
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

  const _VideoSpoofProfile({
    required this.model,
    required this.iosVersion,
    required this.creationTime,
    required this.gpsIso6709,
    required this.crf,
    required this.preset,
    required this.jitterId,
  });

  factory _VideoSpoofProfile.random(Random random) {
    final device = _devices[random.nextInt(_devices.length)];

    // Random timestamp trong 30 ngày qua
    final daysAgo = random.nextInt(30);
    final hoursAgo = random.nextInt(24);
    final minutesAgo = random.nextInt(60);
    final recordedAt = DateTime.now()
        .toUtc()
        .subtract(Duration(days: daysAgo, hours: hoursAgo, minutes: minutesAgo))
        .toIso8601String();

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

    return _VideoSpoofProfile(
      model: device.model,
      iosVersion: device.ios,
      creationTime: recordedAt,
      gpsIso6709: gps,
      crf: crf,
      preset: preset,
      jitterId: jitterId,
    );
  }

  /// Returns ffmpeg metadata args to be added to the command.
  List<String> toFfmpegMetadataArgs() => [
    '-metadata',
    'creation_time=$creationTime',
    '-metadata',
    'com.apple.quicktime.make=Apple',
    '-metadata',
    'com.apple.quicktime.model=$model',
    '-metadata',
    'com.apple.quicktime.software=$iosVersion',
    '-metadata',
    'com.apple.quicktime.location.ISO6709=$gpsIso6709',
    '-metadata',
    'scraki_id=$jitterId',
  ];
}
