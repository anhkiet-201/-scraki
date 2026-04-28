import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/pipeline/pipeline_context.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/pipeline/video_batch_pipeline.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/audio/ambient_audio_provider.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/metadata/video_metadata_analyzer.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';
import '../../factory/video_batch_engine_factory.dart';

@LazySingleton(as: VideoBatchPipeline)
class VideoBatchPipelineImpl implements VideoBatchPipeline {
  final VideoHardwareCapabilityResolver _hardwareResolver;
  final VideoMetadataAnalyzer _metadataAnalyzer;
  final AmbientAudioProvider _ambientAudioProvider;
  
  late PipelineContext _context;
  final _eventController = StreamController<String>.broadcast();

  VideoBatchPipelineImpl(
    this._hardwareResolver,
    this._metadataAnalyzer,
    this._ambientAudioProvider,
  );

  @override
  Stream<String> get events => _eventController.stream;

  @override
  Future<void> plan({
    required List<String> sourceVideoPaths,
    required BatchVideoConfig config,
  }) async {
    _context = PipelineContext(config: config);
    _eventController.add('📋 Đang khởi tạo pipeline...');

    // 1. Hardware Discovery
    await _hardwareResolver.resolve();
    _context.engine = VideoBatchEngineFactory.createEngine(_hardwareResolver, _metadataAnalyzer);
    await _context.engine.initialize();

    _context.gpuInfo = _hardwareResolver.gpuInfo!;

    // 2. Metadata Analysis
    _eventController.add('📋 Kiểm tra video nguồn...');
    final probeResults = await Future.wait(sourceVideoPaths.map((path) => _metadataAnalyzer.probeSourceVideo(path)));

    for (int i = 0; i < sourceVideoPaths.length; i++) {
      if (_context.cancelled) return;
      final path = sourceVideoPaths[i];
      final duration = probeResults[i].duration;
      if (duration >= config.minVideoDuration) {
        _context.validSourceVideos.add(path);
        _context.videoDurations[path] = duration;
        _context.videoHasAudio[path] = probeResults[i].hasAudio;
      }
    }

    if (_context.validSourceVideos.isEmpty) {
      _eventController.add('❌ Không có video hợp lệ!');
      return;
    }

    // 3. Ambient Sourcing
    if (config.generateAmbientAudio) {
      _eventController.add('[0/3] Đang tải âm thanh nền...');
      try {
        final paths = await _ambientAudioProvider.fetchRandomAmbientAudios(
          config.outputCount, 
          config.ambientTags, 
          onLog: (msg) => _eventController.add(msg)
        );
        _context.tempAmbientAudioPaths.addAll(paths);
      } catch (e) {
        _eventController.add('  ⚠️ Lỗi tải ambient audio: $e');
      }
    }

    // 4. Planning (Dynamic Shifting Pool)
    _eventController.add('[1/3] Lập kế hoạch cắt video...');
    _generatePlanning(config);
  }

  @override
  Future<void> executeCutSegments() async {
    if (_context.cancelled) return;
    
    _eventController.add('[2/3] Đang xử lý ${_context.allUniqueSegments.length} segments...');
    
    // Create temp dir
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    _context.tempDir = Directory(p.join(Directory.systemTemp.path, 'scraki_segments_$timestamp'));
    await _context.tempDir.create(recursive: true);

    final activeTasks = <Future<void>>{};
    int completed = 0;
    final maxConcurrent = _context.gpuInfo.maxConcurrentEncodes;

    for (final req in _context.allUniqueSegments) {
      if (_context.cancelled) break;
      while (activeTasks.length >= maxConcurrent) await Future.any(activeTasks);
      
      final outputPath = p.join(_context.tempDir.path, '${req.id}.mp4');
      _context.segmentFileMap[req] = outputPath;

      late Future<void> task;
      task = _context.engine.cutSegment(
        request: req, 
        outputPath: outputPath, 
        context: _context.executionContext,
      ).then((_) {
        activeTasks.remove(task);
        completed++;
        _eventController.add('_PROGRESS_LAZY: ⏳ Đang render segments: $completed/${_context.allUniqueSegments.length}...');
      });
      
      activeTasks.add(task);
    }
    
    if (activeTasks.isNotEmpty) await Future.wait(activeTasks);
  }

  @override
  Future<void> executeRender() async {
    if (_context.cancelled) return;
    
    _eventController.add('[3/3] Đang ghép ${_context.config.outputCount} videos...');
    
    // Prepare output dir
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('-', '').replaceAll('T', '_').substring(0, 15);
    String baseOutputDir;
    if (_context.config.outputDir != null) {
      baseOutputDir = _context.config.outputDir!;
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

    _context.outputDir = p.join(baseOutputDir, 'output_vids_$timestamp');
    await Directory(_context.outputDir).create(recursive: true);

    final activeTasks = <Future<void>>{};
    final maxConcurrent = _context.gpuInfo.maxConcurrentEncodes;

    for (int i = 1; i <= _context.config.outputCount; i++) {
      if (_context.cancelled) break;
      while (activeTasks.length >= maxConcurrent) await Future.any(activeTasks);
      final plan = await _generateCompositionPlan(i);
      
      late Future<void> task;
      task = _context.engine.renderVideo(
        plan: plan, 
        context: _context.executionContext,
        onProgress: (pct) => _eventController.add('_PROGRESS_VID$i: [$i/${_context.config.outputCount}] $pct'),
      ).then((result) {
        activeTasks.remove(task);
        if (result.success) {
          _eventController.add('_UPDATE_VID$i: ✅ Hoàn tất video $i');
        } else {
          _eventController.add('_UPDATE_VID$i: ❌ Thất bại video $i');
        }
      });
      
      activeTasks.add(task);
    }

    if (activeTasks.isNotEmpty) await Future.wait(activeTasks);
    _eventController.add('✅ Hoàn thành pipeline.');
  }

  @override
  void cancel() {
    _context.cancel();
    _eventController.add('🛑 Đã dừng pipeline.');
  }

  void _generatePlanning(BatchVideoConfig config) {
    final random = Random();
    _context.validSourceVideos.shuffle(random); // Shuffle sources first
    
    List<SegmentRequest> globalSegmentPool = _generateSegmentPool(
      _context.validSourceVideos, 
      _context.videoDurations, 
      _context.videoHasAudio, 
      config, 
      random
    );

    if (globalSegmentPool.isEmpty) return;

    int poolIndex = 0;
    for (int i = 1; i <= config.outputCount; i++) {
      final targetDuration = config.minFinalDuration + random.nextInt(config.maxFinalDuration - config.minFinalDuration + 1);
      final selected = <SegmentRequest>[];
      double totalDuration = 0.0;
      String lastVideoPath = '';

      while (totalDuration < targetDuration && !_context.cancelled) {
        if (poolIndex >= globalSegmentPool.length) {
          globalSegmentPool = _generateSegmentPool(_context.validSourceVideos, _context.videoDurations, _context.videoHasAudio, config, random, isRetry: true);
          poolIndex = 0;
        }
        
        int foundIndex = -1;
        // Simple shifting logic kept from original
        for (int checked = 0; checked < min(15, globalSegmentPool.length - poolIndex); checked++) {
           final candidate = globalSegmentPool[poolIndex + checked];
           if ((_context.validSourceVideos.length <= 1 || candidate.sourcePath != lastVideoPath) && !selected.any((s) => s.sourcePath == candidate.sourcePath && s.startTime == candidate.startTime)) {
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
        _context.allUniqueSegments.add(request);
        totalDuration += request.duration;
        lastVideoPath = request.sourcePath;
      }
      _context.videoPlans[i] = selected;
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

  Future<CompositionPlan> _generateCompositionPlan(int index) async {
    final random = Random();
    final config = _context.config;
    
    final params = CompositionParams(
      targetDuration: config.minFinalDuration + random.nextInt(config.maxFinalDuration - config.minFinalDuration + 1),
      pts: 0.99 + random.nextDouble() * 0.02,
      brightness: (random.nextDouble() * 0.04) - 0.02,
      contrast: 1.0 + (random.nextDouble() * 0.04) - 0.02,
      gopSize: 60 + random.nextInt(60),
      creationTime: '${DateTime.now().toUtc().toIso8601String().split('.').first}.000000Z',
      audioProfile: AudioSpoofProfile.random(random),
      hueShift: (random.nextDouble() * 6.0) - 3.0,
      satFactor: 0.97 + random.nextDouble() * 0.06,
      vignetteAngle: pi / 100 + random.nextDouble() * (pi / 100),
      zoomVal: 1.02 + (random.nextDouble() * 0.02),
      randX: random.nextDouble(),
      randY: random.nextDouble(),
      colorProfile: config.generateColorFilter ? ColorFilterProfile.random(random) : null,
      curvesProfile: config.generateColorFilter ? CurvesProfile.random(random) : null,
      balanceProfile: config.generateColorFilter ? ColorBalanceProfile.random(random) : null,
      gamma: config.generateColorFilter ? 0.98 + random.nextDouble() * 0.04 : null,
      gammaR: !config.generateColorFilter ? 0.98 + random.nextDouble() * 0.04 : null,
      gammaG: !config.generateColorFilter ? 0.98 + random.nextDouble() * 0.04 : null,
      gammaB: !config.generateColorFilter ? 0.98 + random.nextDouble() * 0.04 : null,
    );

    final plan = _context.videoPlans[index]!;
    final segmentsToMerge = plan.map((r) => _context.segmentFileMap[r]!).toList();
    final ambientPath = (_context.tempAmbientAudioPaths.isNotEmpty && index - 1 < _context.tempAmbientAudioPaths.length) ? _context.tempAmbientAudioPaths[index - 1] : null;

    final hasCustomAudio = config.customAudioPath != null && config.customAudioPath!.isNotEmpty && File(config.customAudioPath!).existsSync();
    
    // Prepare text overlays
    final textPaths = <String>[];
    for (var i = 0; i < config.textOverlays.length; i++) {
      final file = File(p.join(_context.tempDir.path, 'text_${index}_$i.png'));
      await file.writeAsBytes(config.textOverlays[i].bytes);
      textPaths.add(file.absolute.path);
    }

    return CompositionPlan(
      outputIndex: index,
      segmentPaths: segmentsToMerge,
      outputDir: _context.outputDir,
      config: config,
      params: params,
      ambientAudioPath: ambientPath,
      textOverlayPaths: textPaths,
      hasCustomAudio: hasCustomAudio,
      hasAmbientAudio: ambientPath != null,
    );
  }
}
