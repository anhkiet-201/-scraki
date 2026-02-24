import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

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

  const BatchVideoConfig({
    this.minSegmentDuration = 4,
    this.maxSegmentDuration = 6,
    this.minVideoDuration = 3,
    this.minFinalDuration = 30,
    this.maxFinalDuration = 40,
    this.outputCount = 10,
    this.outputDir,
    this.overlayBytes,
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
        yield '  [Video $videoIndex] Đang chuẩn bị cắt...';

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
      for (int i = 1; i <= config.outputCount; i++) {
        if (_cancelled) break;
        yield '  [$i/${config.outputCount}] Đang tạo video $i...';
        final success = await _createOutputVideo(
          outputIndex: i,
          segments: segments,
          outputDir: outputDir,
          config: config,
          overlayFile: overlayFile,
          onLogMsg: (msg) {
            onLog?.call(msg);
          },
          onProgress: (percent) {
            final p = (percent * 100).toStringAsFixed(0);
            onLog?.call(
              '_PROGRESS_:  [$i/${config.outputCount}] Đang tạo video $i... $p%',
            );
          },
        );
        if (success) {
          yield '_UPDATE_  [$i/${config.outputCount}] ✓';
        } else {
          yield '_UPDATE_  [$i/${config.outputCount}] ✗ (thất bại)';
        }
      }

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

  /// Cuts a single source video into 4-6 second segments in parallel (max 4).
  Future<List<String>> _cutVideoToSegments({
    required String video,
    required int videoIndex,
    required int duration,
    required BatchVideoConfig config,
    required String tempDir,
    required void Function(String) onLog,
  }) async {
    final random = Random();
    final futures = <Future<String?>>[];
    int currentTime = 0;
    int segmentIndex = 0;
    int completedSegments = 0;

    while (currentTime < duration) {
      if (_cancelled) break;

      // Random segment length between min and max
      final segDuration =
          config.minSegmentDuration +
          random.nextInt(
            config.maxSegmentDuration - config.minSegmentDuration + 1,
          );
      final remaining = duration - currentTime;
      final actualDuration = min(segDuration, remaining);

      // Skip segments shorter than 2s
      if (actualDuration < 2) break;

      segmentIndex++;
      final vidIdx = videoIndex.toString().padLeft(3, '0');
      final segIdx = segmentIndex.toString().padLeft(3, '0');
      final outputPath = '$tempDir/video${vidIdx}_seg$segIdx.mp4';

      final processName = 'V${vidIdx}_S$segIdx';

      futures.add(
        _runSegmentCut(
          input: video,
          startSeconds: currentTime,
          duration: actualDuration,
          output: outputPath,
          processName: processName,
          onProgress: (percent) {
            // Throttling or custom UI can be done. Since segments are fast,
            // printing every single percent might flood log, we just yield it in UI buffer
            // but for simplicity we only yield at specific milestones or let UI handle the single dynamic line
            // Currently, Store appends lines. We'll wait until full percent progress logic.
          },
        ).then((res) {
          completedSegments++;
          if (!_cancelled) {
            onLog(
              '_PROGRESS_: Đang cắt video $videoIndex: Hoàn thành $completedSegments segment(s)...',
            );
          }
          return res;
        }),
      );

      // Limit to 4 concurrent ffmpeg processes
      if (futures.length >= 4) {
        await Future.wait(futures);
        futures.clear();
      }

      currentTime += actualDuration;
    }

    // Wait for remaining
    if (futures.isNotEmpty) await Future.wait(futures);

    // Clear the progress line so it stays as a completed note
    onLog(
      '_UPDATE_  [Video $videoIndex] ✓ Hoàn thành cắt $completedSegments segment(s).',
    );

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
  Future<String?> _runSegmentCut({
    required String input,
    required int startSeconds,
    required int duration,
    required String output,
    String? processName,
    void Function(double)? onProgress,
  }) async {
    try {
      final process = await Process.start(_ffmpegBin, [
        '-hide_banner',
        '-y',
        '-ss',
        startSeconds.toString(),
        '-i',
        input,
        '-t',
        duration.toString(),
        // Scale to 1080x1920 (9:16), crop to exact size, set 30fps
        '-vf',
        'scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30',
        '-af',
        'volume=0.05',
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-crf',
        '26',
        '-c:a',
        'aac',
        '-b:a',
        '128k',
        '-ar',
        '44100',
        '-movflags',
        '+faststart',
        output,
      ]);
      _activeProcesses.add(process);

      // Parse stderr for time=...
      final regex = RegExp(r'time=(\d{2}):(\d{2}):(\d{2}\.\d{2})');
      process.stderr.listen((data) {
        if (onProgress == null || _cancelled) return;
        final output = String.fromCharCodes(data);
        final match = regex.firstMatch(output);
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
      return exitCode == 0 ? output : null;
    } catch (_) {
      return null;
    }
  }

  /// Builds a concat list, selects diverse segments, and runs ffmpeg with
  /// randomized anti-reup filters (PTS warp, brightness, contrast, noise).
  Future<bool> _createOutputVideo({
    required int outputIndex,
    required List<String> segments,
    required String outputDir,
    required BatchVideoConfig config,
    void Function(double)? onProgress,
    void Function(String)? onLogMsg,
    File? overlayFile,
  }) async {
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

      // Rút ngẫu nhiên từ pool segment 1 lần (sau khi suffle)
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
      // Yêu cầu từ USER: Nếu không đủ thời lượng thì báo thất bại, không tái sử dụng segment cũ
      onLogMsg?.call(
        '  ⚠️ Video $outputIndex thất bại: Chỉ gom được ${totalDuration}s (cần tối thiểu ${targetDuration}s). Vui lòng thêm video gốc.',
      );
      return false;
    }

    if (selected.isEmpty) return false;

    // Write concat list to a temp file
    final concatFile = File(
      '${Directory.systemTemp.path}/scraki_concat_${outputIndex}_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    final buffer = StringBuffer();
    for (final seg in selected) {
      // Use absolute paths; ffmpeg concat requires forward slashes even on Windows
      final absPath = File(seg).absolute.path.replaceAll('\\', '/');
      buffer.writeln("file '$absPath'");
    }
    await concatFile.writeAsString(buffer.toString());

    // ── Random anti-reup parameters ─────────────────────────────────────────
    // Replicate make-vid.sh random PTS/tempo/brightness/contrast/noise logic
    final pts = 0.96 + random.nextDouble() * 0.08; // video speed 0.96x – 1.04x
    final tempo = 1.0 / pts; // audio tempo inverse of video pts
    final brightness = (random.nextDouble() * 0.06) - 0.03; // -0.03 to +0.03
    final contrast = 1.0 + random.nextDouble() * 0.05; // 1.00 to 1.05
    final noise = 1.0 + random.nextDouble() * 3.0; // noise strength 1-4

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

      if (overlayFile != null) {
        // Complex filter approach for text overlay
        ffmpegArgs.addAll([
          '-loop',
          '1',
          '-i',
          overlayFile.absolute.path,
          '-filter_complex',
          '[0:v]scale=1080:1920:force_original_aspect_ratio=increase:flags=lanczos,'
              'crop=1080:1920,'
              'eq=brightness=$brightnessStr:contrast=$contrastStr,'
              'noise=alls=$noiseStr:allf=t,'
              'setpts=${ptsStr}*PTS[bg];'
              '[bg][1:v]overlay=0:0:shortest=1[outv];'
              '[0:a]volume=0.05,atempo=$tempoStr[outa]',
          '-map',
          '[outv]',
          '-map',
          '[outa]',
          '-c:v',
          'libx264',
          '-preset',
          'ultrafast',
          '-crf',
          '26',
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
          '-movflags',
          '+faststart',
          finalOutput,
        ]);
      } else {
        // Simple filter approach without overlay
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
          'ultrafast',
          '-crf',
          '26',
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
          '-movflags',
          '+faststart',
          finalOutput,
        ]);
      }

      final process = await Process.start(_ffmpegBin, ffmpegArgs);

      _activeProcesses.add(process);

      // Target duration approximate
      final regex = RegExp(r'time=(\d{2}):(\d{2}):(\d{2}\.\d{2})');
      process.stderr.listen((data) {
        if (onProgress == null || _cancelled) return;
        final output = String.fromCharCodes(data);
        final match = regex.firstMatch(output);
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

      return exitCode == 0 && File(finalOutput).existsSync();
    } catch (_) {
      return false;
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
}
