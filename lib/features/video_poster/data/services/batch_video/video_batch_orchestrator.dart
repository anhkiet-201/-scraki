import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:injectable/injectable.dart';

// Domain Entities
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';

// Engines & Models
import 'models/batch_video_models.dart';
import 'models/video_batch_execution_context.dart';
import 'engines/hardware/video_hardware_capability_resolver.dart';
import 'engines/metadata/video_metadata_analyzer.dart';
import 'engines/segment/video_segment_processor.dart';
import 'engines/composition/video_batch_composer.dart';
import 'engines/audio/ambient_audio_provider.dart';

@lazySingleton
class VideoBatchOrchestrator {
  final VideoHardwareCapabilityResolver _hardwareResolver;
  final VideoMetadataAnalyzer _metadataAnalyzer;
  final VideoSegmentProcessor _segmentProcessor;
  final VideoBatchComposer _composer;
  final AmbientAudioProvider _ambientAudioProvider;
  
  VideoBatchExecutionContext? _currentContext;

  VideoBatchOrchestrator(
    this._hardwareResolver,
    this._metadataAnalyzer,
    this._segmentProcessor,
    this._composer,
    this._ambientAudioProvider,
  );

  /// Runs the full batch video creation pipeline.
  Stream<String> createBatchVideos({
    required List<String> sourceVideoPaths,
    required BatchVideoConfig config,
    void Function(String dir)? onOutputDir,
    void Function(String log)? onLog,
  }) async* {
    _currentContext = VideoBatchExecutionContext();
    final context = _currentContext!;
    _hardwareResolver.clearCache();
    _metadataAnalyzer.clearCache();

    final tempAmbientAudioPaths = <String>[];

    // Validate ffmpeg availability
    if (!await _hardwareResolver.checkFfmpeg()) {
      yield '❌ FFmpeg chưa được cài đặt! Vui lòng cài FFmpeg trước.';
      yield '   macOS: brew install ffmpeg';
      yield '   Windows: https://ffmpeg.org/download.html';
      return;
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('-', '').replaceAll('T', '_').substring(0, 15);
    
    // Get Output Directory
    String baseOutputDir;
    if (config.outputDir != null) {
      baseOutputDir = config.outputDir!;
    } else {
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'];
          baseOutputDir = (userProfile != null && await Directory(p.join(userProfile, 'Desktop')).exists())
              ? p.join(userProfile, 'Desktop')
              : p.join(documentsDir.parent.path, 'Desktop');
        } else {
          baseOutputDir = p.join(documentsDir.parent.path, 'Desktop');
        }
        if (!await Directory(baseOutputDir).exists()) baseOutputDir = Directory.current.path;
      } catch (_) {
        baseOutputDir = Directory.current.path;
      }
    }

    final outputDir = p.join(baseOutputDir, 'output_vids_$timestamp');
    final tempDir = Directory(p.join(Directory.systemTemp.path, 'scraki_segments_$timestamp'));
    await tempDir.create(recursive: true);

    try {
      yield '📋 Kiểm tra video nguồn...';
      final probeResults = await Future.wait(sourceVideoPaths.map((path) => _metadataAnalyzer.probeSourceVideo(path)));

      final validVideos = <String>[];
      final videoDurations = <String, int>{};
      final videoHasAudio = <String, bool>{};

      for (int i = 0; i < sourceVideoPaths.length; i++) {
        if (context.cancelled) return;
        final path = sourceVideoPaths[i];
        final duration = probeResults[i].duration;
        if (duration >= config.minVideoDuration) {
          validVideos.add(path);
          videoDurations[path] = duration;
          videoHasAudio[path] = probeResults[i].hasAudio;
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
          final paths = await _ambientAudioProvider.fetchRandomAmbientAudios(config.outputCount, config.ambientTags, onLog: (msg) => onLog?.call(msg));
          tempAmbientAudioPaths.addAll(paths);
        } catch (e) {
          yield '  ⚠️ Lỗi tải ambient audio: $e. Sẽ tiếp tục không có ambient.';
        }
      }

      // Step 2: Planning
      yield '';
      yield '[1/3] Lập kế hoạch cắt video (Dynamic Shifting Pool)...';
      final random = Random();
      List<SegmentRequest> globalSegmentPool = _generateSegmentPool(validVideos, videoDurations, videoHasAudio, config, random);
      if (globalSegmentPool.isEmpty) {
        yield '❌ Lỗi: Nhóm video gốc quá ngắn!';
        return;
      }

      int poolIndex = 0;
      final videoPlans = <int, List<SegmentRequest>>{};
      final allUniqueSegments = <SegmentRequest>{};

      for (int i = 1; i <= config.outputCount; i++) {
        final targetDuration = config.minFinalDuration + random.nextInt(config.maxFinalDuration - config.minFinalDuration + 1);
        final selected = <SegmentRequest>[];
        double totalDuration = 0.0;
        String lastVideoPath = '';

        while (totalDuration < targetDuration && !context.cancelled) {
          if (poolIndex >= globalSegmentPool.length) {
            globalSegmentPool = _generateSegmentPool(validVideos, videoDurations, videoHasAudio, config, random, isRetry: true);
            poolIndex = 0;
          }
          // Simple shifting logic kept from original
          int foundIndex = -1;
          for (int checked = 0; checked < min(15, globalSegmentPool.length - poolIndex); checked++) {
             final candidate = globalSegmentPool[poolIndex + checked];
             if ((validVideos.length <= 1 || candidate.sourcePath != lastVideoPath) && !selected.any((s) => s.sourcePath == candidate.sourcePath && s.startTime == candidate.startTime)) {
                foundIndex = poolIndex + checked;
                break;
             }
          }
          if (foundIndex != -1 && foundIndex != poolIndex) {
              final temp = globalSegmentPool[poolIndex];
              globalSegmentPool[poolIndex] = globalSegmentPool[foundIndex];
              globalSegmentPool[foundIndex] = temp;
          }
          final request = globalSegmentPool[poolIndex++];
          selected.add(request);
          allUniqueSegments.add(request);
          totalDuration += request.duration;
          lastVideoPath = request.sourcePath;
        }
        videoPlans[i] = selected;
      }

      // Step 3: Render unique segments
      yield '';
      yield '[2/3] Đang xử lý ${allUniqueSegments.length} segments...';
      final segmentFileMap = <SegmentRequest, String>{};
      final activeCutTasks = <Future<void>>{};
      int completedSegments = 0;
      final gpu = await _hardwareResolver.getGpuInfo();
      final maxCutTasks = gpu.maxConcurrentEncodes;

      onLog?.call('_PROGRESS_LAZY: ⏳ Đang render segments: 0/${allUniqueSegments.length}...');

      for (final req in allUniqueSegments) {
        if (context.cancelled) break;
        while (activeCutTasks.length >= maxCutTasks) await Future.any(activeCutTasks);
        if (context.cancelled) break;

        final outputPath = p.join(tempDir.path, '${req.id}.mp4');
        segmentFileMap[req] = outputPath;

        late Future<void> task;
        task = _segmentProcessor.runSegmentCut(
          input: req.sourcePath, startSeconds: req.startTime, duration: req.duration, output: outputPath,
          hflip: req.hflip, hasAudio: req.hasAudio, processName: req.id, context: context, onLogMsg: onLog,
        ).then((_) {
          activeCutTasks.remove(task);
          completedSegments++;
          onLog?.call('_PROGRESS_LAZY: ⏳ Đang render segments: $completedSegments/${allUniqueSegments.length}...');
        });
        activeCutTasks.add(task);
      }
      if (activeCutTasks.isNotEmpty) await Future.wait(activeCutTasks);
      if (context.cancelled) { yield '🛑 Đã dừng.'; return; }

      // Step 4: Create output videos
      yield '';
      yield '[3/3] Đang ghép ${config.outputCount} videos...';
      await Directory(outputDir).create(recursive: true);
      onOutputDir?.call(Directory(outputDir).absolute.path);

      int successCount = 0;
      final activeTasks = <Future<void>>{};
      int currentIndex = 1;
      final streamController = StreamController<String>();
      final streamPump = streamController.stream.listen((log) => onLog?.call(log));

      while (currentIndex <= config.outputCount || activeTasks.isNotEmpty) {
        if (context.cancelled) break;
        while (activeTasks.length >= maxCutTasks) await Future.any(activeTasks);
        if (context.cancelled) break;

        if (currentIndex <= config.outputCount) {
          final i = currentIndex++;
          final plan = videoPlans[i]!;
          final segmentsToMerge = plan.map((r) => segmentFileMap[r]!).toList();
          final ambientPath = (tempAmbientAudioPaths.isNotEmpty && i - 1 < tempAmbientAudioPaths.length) ? tempAmbientAudioPaths[i - 1] : null;

          late Future<void> taskFuture;
          taskFuture = _composer.createOutputVideo(
            outputIndex: i, segments: segmentsToMerge, outputDir: outputDir, config: config, context: context,
            ambientAudioPath: ambientPath,
            onProgress: (percent) {
              if (context.cancelled) return;
              streamController.add('_PROGRESS_VID$i: [$i/${config.outputCount}] Đang ghép video $i... ${(percent * 100).toStringAsFixed(0)}%');
            },
          ).then((result) {
            activeTasks.remove(taskFuture);
            if (!context.cancelled) {
              for (final log in result.logs) streamController.add(log);
              if (result.success) {
                successCount++;
                streamController.add('_UPDATE_VID$i [$i/${config.outputCount}] ✓ Hoàn tất video $i');
              } else {
                streamController.add('_UPDATE_VID$i [$i/${config.outputCount}] ✗ (thất bại video $i)');
              }
            }
          });
          activeTasks.add(taskFuture);
        } else {
          if (activeTasks.isNotEmpty) await Future.any(activeTasks);
        }
      }
      if (activeTasks.isNotEmpty) await Future.wait(activeTasks);
      await streamController.close();
      await streamPump.cancel();

      yield context.cancelled ? '🛑 Đã dừng. Hoàn thành $successCount/${config.outputCount} videos.' : '\n✅ Hoàn thành — $successCount/${config.outputCount} videos → $outputDir';
    } finally {
      try { if (await tempDir.exists()) await tempDir.delete(recursive: true); } catch (_) {}
      for (final path in tempAmbientAudioPaths) { try { final f = File(path); if (await f.exists()) await f.delete(); } catch (_) {} }
    }
  }

  List<SegmentRequest> _generateSegmentPool(List<String> validVideos, Map<String, int> videoDurations, Map<String, bool> videoHasAudio, BatchVideoConfig config, Random random, {bool isRetry = false}) {
    final pool = <SegmentRequest>[];
    for (final src in List<String>.from(validVideos)..shuffle(random)) {
      final srcDur = videoDurations[src]!.toDouble();
      double currentTime = (srcDur > config.minSegmentDuration + 2) ? random.nextDouble() * 2.0 : 0.0;
      while (currentTime + config.minSegmentDuration <= srcDur) {
        double maxPossible = min(config.maxSegmentDuration.toDouble(), srcDur - currentTime);
        if (maxPossible < config.minSegmentDuration) break;
        final segDur = config.minSegmentDuration + (random.nextDouble() * (maxPossible - config.minSegmentDuration));
        pool.add(SegmentRequest(sourcePath: src, startTime: currentTime, duration: segDur, hflip: random.nextDouble() < (isRetry ? 0.7 : 0.3), hasAudio: videoHasAudio[src] ?? false));
        currentTime += segDur;
      }
    }
    return pool..shuffle(random);
  }

  /// Cancels the current running batch.
  void cancel() {
    _currentContext?.cancel();
    _currentContext = null;
  }
}
