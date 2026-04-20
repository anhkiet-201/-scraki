import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:injectable/injectable.dart';

// Domain Entities
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';

// Sub-modules
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/mixins/batch_video_state_mixin.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/mixins/batch_video_gpu_mixin.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/mixins/batch_video_probe_mixin.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/mixins/batch_video_segment_mixin.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/mixins/batch_video_render_mixin.dart';

import 'package:scraki/features/video_poster/data/services/ambient_audio_service.dart';

// ============================================================================
// BatchVideoService — Cross-platform Dart reimagplementation of make-vid.sh
// Works on macOS & Windows by calling ffmpeg/ffprobe via dart:io Process.
// Refactored to use Mixins for maintainability.
// ============================================================================

@lazySingleton
class BatchVideoService with 
    BatchVideoStateMixin, 
    BatchVideoGpuMixin, 
    BatchVideoProbeMixin, 
    BatchVideoSegmentMixin, 
    BatchVideoRenderMixin {
    
  final AmbientAudioService _ambientAudioService;

  BatchVideoService(this._ambientAudioService);

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
    resetState();
    clearGpuCache();
    clearProbeCache();

    final tempAmbientAudioPaths = <String>[];

    // Validate ffmpeg availability
    if (!await checkFfmpeg()) {
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
        final documentsDir = await getApplicationDocumentsDirectory();
        
        if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'];
          if (userProfile != null) {
            final desktopPath = p.join(userProfile, 'Desktop');
            if (await Directory(desktopPath).exists()) {
              baseOutputDir = desktopPath;
            } else {
              baseOutputDir = p.join(documentsDir.parent.path, 'Desktop');
            }
          } else {
            baseOutputDir = p.join(documentsDir.parent.path, 'Desktop');
          }
        } else {
          baseOutputDir = p.join(documentsDir.parent.path, 'Desktop');
        }

        if (!await Directory(baseOutputDir).exists()) {
          baseOutputDir = Directory.current.path;
        }
      } catch (_) {
        baseOutputDir = Directory.current.path;
      }
    }

    final outputDir = p.join(baseOutputDir, 'output_vids_$timestamp');

    final tempDir = Directory(
      p.join(Directory.systemTemp.path, 'scraki_segments_$timestamp'),
    );
    await tempDir.create(recursive: true);

    try {
      // ── Step 1: Validate inputs & probe all source videos in parallel ─────
      yield '📋 Kiểm tra video nguồn...';

      final probeResults = await Future.wait(
        sourceVideoPaths.map((path) => probeSourceVideo(path)),
      );

      final validVideos = <String>[];
      final videoDurations = <String, int>{};
      final videoHasAudio = <String, bool>{};

      for (int i = 0; i < sourceVideoPaths.length; i++) {
        if (cancelled) return;
        final path = sourceVideoPaths[i];
        final duration = probeResults[i].duration;
        if (duration >= config.minVideoDuration) {
          validVideos.add(path);
          videoDurations[path] = duration;
          videoHasAudio[path] = probeResults[i].hasAudio;
          colorInfoCache[path] = probeResults[i].colorInfo;
        } else {
          yield '⚠️  Bỏ qua: ${p.basename(path)} (quá ngắn: ${duration}s)';
        }
      }

      if (validVideos.isEmpty) {
        yield '❌ Không có video hợp lệ để xử lý!';
        return;
      }
      yield '✅ ${validVideos.length} video hợp lệ';

      // Step 1.5: Fetch Ambient Audio
      if (config.generateAmbientAudio) {
        yield '';
        yield '[0/3] Đang tải âm thanh nền (Ambient Audio)...';
        try {
          final paths = await _ambientAudioService.fetchRandomAmbientAudios(
            config.outputCount, 
            config.ambientTags, 
            onLog: (msg) => onLog?.call(msg)
          );
          tempAmbientAudioPaths.addAll(paths);
        } catch (e) {
          yield '  ⚠️ Lỗi tải ambient audio: $e. Sẽ tiếp tục không có ambient.';
        }
      }

      // -- Step 2: Planning (Dynamic shifting pool) --
      yield '';
      yield '[1/3] Lập kế hoạch cắt video (Dynamic Shifting Pool)...';
      final random = Random();

      List<SegmentRequest> globalSegmentPool = generateSegmentPool(
        validVideos: validVideos,
        videoDurations: videoDurations,
        videoHasAudio: videoHasAudio,
        config: config,
        random: random,
      );

      if (globalSegmentPool.isEmpty) {
        yield '❌ Lỗi: Nhóm video gốc quá ngắn, không thể lấy được đoạn cắt nào!';
        return;
      }
      int poolIndex = 0;

      final videoPlans = <int, List<SegmentRequest>>{};
      final allUniqueSegments = <SegmentRequest>{};

      for (int i = 1; i <= config.outputCount; i++) {
        final targetDuration =
            config.minFinalDuration +
            random.nextInt(
              config.maxFinalDuration - config.minFinalDuration + 1,
            );

        final selected = <SegmentRequest>[];
        double totalDuration = 0.0;
        String lastVideoPath = '';

        while (totalDuration < targetDuration && !cancelled) {
          if (poolIndex >= globalSegmentPool.length) {
            globalSegmentPool = generateSegmentPool(
              validVideos: validVideos,
              videoDurations: videoDurations,
              videoHasAudio: videoHasAudio,
              config: config,
              random: random,
              isRetry: true,
            );
            poolIndex = 0;
          }

          int foundIndex = -1;
          for (int checked = 0; checked < min(15, globalSegmentPool.length - poolIndex); checked++) {
             final candidate = globalSegmentPool[poolIndex + checked];
             bool diffSource = (validVideos.length <= 1) || (candidate.sourcePath != lastVideoPath);
             bool alreadyInVideo = selected.any((s) => s.sourcePath == candidate.sourcePath && s.startTime == candidate.startTime);
             
             if (diffSource && !alreadyInVideo) {
                foundIndex = poolIndex + checked;
                break;
             }
          }

          if (foundIndex != -1 && foundIndex != poolIndex) {
              final temp = globalSegmentPool[poolIndex];
              globalSegmentPool[poolIndex] = globalSegmentPool[foundIndex];
              globalSegmentPool[foundIndex] = temp;
          }

          final request = globalSegmentPool[poolIndex];
          poolIndex++;

          selected.add(request);
          allUniqueSegments.add(request);
          totalDuration += request.duration;
          lastVideoPath = request.sourcePath;
        }
        videoPlans[i] = selected;
      }

      // ── Step 3: Render unique segments ───────────────────────────────────
      yield '';
      yield '[2/3] Đang xử lý ${allUniqueSegments.length} segments...';

      final segmentFileMap = <SegmentRequest, String>{};
      final activeCutTasks = <Future<void>>{};
      int completedSegments = 0;
      final totalSegments = allUniqueSegments.length;

      onLog?.call('_PROGRESS_LAZY: ⏳ Đang render segments: 0/$totalSegments...');

      for (final req in allUniqueSegments) {
        if (cancelled) break;

        while (activeCutTasks.length >= BatchVideoSegmentMixin.maxConcurrentTasks) {
          await Future.any(activeCutTasks);
        }
        if (cancelled) break;

        final outputPath = p.join(tempDir.path, '${req.id}.mp4');
        segmentFileMap[req] = outputPath;

        late Future<void> task;
        task =
            runSegmentCut(
              input: req.sourcePath,
              startSeconds: req.startTime,
              duration: req.duration,
              output: outputPath,
              hflip: req.hflip,
              hasAudio: req.hasAudio,
              processName: req.id,
              onLogMsg: onLog,
            ).then((_) {
              activeCutTasks.remove(task);
              completedSegments++;
              onLog?.call(
                '_PROGRESS_LAZY: ⏳ Đang render segments: $completedSegments/$totalSegments...',
              );
            });
        activeCutTasks.add(task);
      }
      if (activeCutTasks.isNotEmpty) await Future.wait(activeCutTasks);

      if (cancelled) {
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
        final ambientPath = (tempAmbientAudioPaths.isNotEmpty && i - 1 < tempAmbientAudioPaths.length) 
            ? tempAmbientAudioPaths[i - 1] 
            : null;

        late Future<void> taskFuture;
        taskFuture = createOutputVideo(
          outputIndex: i,
          segments: segmentsToMerge,
          outputDir: outputDir,
          config: config,
          ambientAudioPath: ambientPath,
          onProgress: (percent) {
            if (cancelled) return;
            final pStr = (percent * 100).toStringAsFixed(0);
            streamController.add(
              '_PROGRESS_VID$i: [$i/${config.outputCount}] Đang ghép video $i... $pStr%',
            );
          },
        ).then((result) {
              activeTasks.remove(taskFuture);
              if (!cancelled) {
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
        if (cancelled) break;
        while (activeTasks.length >= BatchVideoSegmentMixin.maxConcurrentTasks) {
          await Future.any(activeTasks);
        }
        if (cancelled) break;
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

      if (cancelled) {
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
      
      // Cleanup ambient audio temp files
      for (final path in tempAmbientAudioPaths) {
         try {
            final file = File(path);
            if (await file.exists()) await file.delete();
         } catch (_) {}
      }
    }
  }

  /// Cancels the running batch by killing all tracked ffmpeg processes.
  void cancel() {
    cancelled = true;
    final processes = List<Process>.from(activeProcesses);
    activeProcesses.clear();
    for (final process in processes) {
      try {
        if (Platform.isWindows) {
          process.kill();
        } else {
          process.kill(ProcessSignal.sigterm);
        }
      } catch (_) {}
    }
  }
}
