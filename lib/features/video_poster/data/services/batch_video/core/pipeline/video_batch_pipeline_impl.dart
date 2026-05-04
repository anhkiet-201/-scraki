import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/pipeline/pipeline_context.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/pipeline/video_batch_pipeline.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/audio/ambient_audio_provider.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/metadata/video_metadata_analyzer.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/common/lut_asset_provider.dart';
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';
import '../../factory/video_batch_engine_factory.dart';

@LazySingleton(as: VideoBatchPipeline)
class VideoBatchPipelineImpl implements VideoBatchPipeline {
  final VideoHardwareCapabilityResolver _hardwareResolver;
  final VideoMetadataAnalyzer _metadataAnalyzer;
  final AmbientAudioProvider _ambientAudioProvider;
  
  late PipelineContext _context;
  bool _isContextInitialized = false;
  bool _isProcessing = false;

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
    if (_isProcessing) return;
    _isProcessing = true;
    
    _context = PipelineContext(config: config);
    _isContextInitialized = true;
    _eventController.add('📋 Đang khởi tạo pipeline...');



    final ctx = _context;
    // 1. Hardware Discovery
    await _hardwareResolver.resolve();
    ctx.engine = VideoBatchEngineFactory.createEngine(_hardwareResolver, _metadataAnalyzer);
    await ctx.engine.initialize();

    ctx.gpuInfo = _hardwareResolver.gpuInfo!;
    _eventController.add('🚀 Phần cứng: ${ctx.gpuInfo.name} | Encoder: ${ctx.gpuInfo.encoder} | Luồng: ${ctx.gpuInfo.maxConcurrentEncodes}');
    if (ctx.gpuInfo.hwaccel != null) {
      _eventController.add('  💡 Tăng tốc: ${ctx.gpuInfo.hwaccel} | PixFmt: ${ctx.gpuInfo.preferredPixFmt}');
    }




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
      _eventController.add('❌ Không tìm thấy video hợp lệ thỏa mãn yêu cầu thời lượng!');
      _isProcessing = false;
      return;
    }
    _eventController.add('✅ Tìm thấy ${_context.validSourceVideos.length} video hợp lệ.');



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
    if (!_isContextInitialized || _context.cancelled) return;
    final ctx = _context;
    
    _eventController.add('[2/3] Đang xử lý ${ctx.allUniqueSegments.length} segments...');
    
    // Create temp dir
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    ctx.tempDir = Directory(p.join(Directory.systemTemp.path, 'scraki_segments_$timestamp'));
    await ctx.tempDir.create(recursive: true);

    final activeTasks = <Future<void>>{};
    int completed = 0;
    final maxConcurrent = ctx.gpuInfo.maxConcurrentEncodes;

    for (final req in ctx.allUniqueSegments) {
      if (ctx.cancelled) break;
      while (activeTasks.length >= maxConcurrent) await Future.any(activeTasks);
      
      final outputPath = p.join(ctx.tempDir.path, '${req.id}.mp4');
      ctx.segmentFileMap[req] = outputPath;

      late Future<void> task;
      task = ctx.engine.cutSegment(
        request: req, 
        outputPath: outputPath, 
        context: ctx.executionContext,
      ).then((_) {
        if (_context != ctx) return; // Bỏ qua nếu đã bắt đầu session mới
        activeTasks.remove(task);
        completed++;
        final pct = (completed / ctx.allUniqueSegments.length * 100).toStringAsFixed(0);
        _eventController.add('_PROGRESS_LAZY: ⏳ Đang cắt ghép: $pct% ($completed/${ctx.allUniqueSegments.length})');
      });
      
      activeTasks.add(task);
    }
    
    if (activeTasks.isNotEmpty) await Future.wait(activeTasks);
  }


  @override
  Future<void> executeRender() async {
    if (!_isContextInitialized || _context.cancelled) {
      _isProcessing = false;
      return;
    }
    final ctx = _context;
    
    _eventController.add('[3/3] Đang ghép ${ctx.config.outputCount} videos...');
    
    // Prepare output dir
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('-', '').replaceAll('T', '_').substring(0, 15);
    String baseOutputDir;
    if (ctx.config.outputDir != null) {
      baseOutputDir = ctx.config.outputDir!;
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

    ctx.outputDir = p.join(baseOutputDir, 'output_vids_$timestamp');
    await Directory(ctx.outputDir).create(recursive: true);

    final activeTasks = <Future<void>>{};
    final maxConcurrent = ctx.gpuInfo.maxConcurrentEncodes;

    for (int i = 1; i <= ctx.config.outputCount; i++) {
      if (ctx.cancelled) break;
      while (activeTasks.length >= maxConcurrent) await Future.any(activeTasks);
      final plan = await _generateCompositionPlan(ctx, i);
      
      late Future<void> task;
      task = ctx.engine.renderVideo(
        plan: plan, 
        context: ctx.executionContext,
        onProgress: (pct) {
          if (_context != ctx) return;
          final progress = (pct * 100).toStringAsFixed(0);
          _eventController.add('_PROGRESS_VID$i: [$i/${ctx.config.outputCount}] Đang xử lý: $progress%');
        },
      ).then((result) {
        if (_context != ctx) return;
        activeTasks.remove(task);
        if (result.success) {
          _eventController.add('_PROGRESS_VID$i: ✅ Hoàn tất video $i');
        } else {
          logger.e('❌ Thất bại video $i: ${result.logs}');
          _eventController.add('_PROGRESS_VID$i: ❌ Thất bại video $i');
        }
      });
      
      activeTasks.add(task);
    }

    if (activeTasks.isNotEmpty) await Future.wait(activeTasks);
    _eventController.add('✅ Hoàn thành pipeline.');
    _isProcessing = false;
  }


  @override
  void cancel() {
    if (_isContextInitialized) {
      try {
        _context.cancel();
      } catch (_) {}
    }
    _isProcessing = false;
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

  Future<CompositionPlan> _generateCompositionPlan(PipelineContext ctx, int index) async {
    final random = Random();
    final config = ctx.config;
    
    final params = CompositionParams(
      targetDuration: config.minFinalDuration + random.nextInt(config.maxFinalDuration - config.minFinalDuration + 1),
      pts: 0.99 + random.nextDouble() * 0.02,
      brightness: _gaussian(random) * 0.015,
      contrast: 1.0 + _gaussian(random) * 0.02,
      gopSize: 48 + random.nextInt(144), // Mở rộng range 48-192
      bFrames: [0, 2, 3][random.nextInt(3)],
      creationTime: '${DateTime.now().toUtc().toIso8601String().split('.').first}.000000Z',
      audioProfile: AudioSpoofProfile.random(random),
      hueShift: _gaussian(random) * 2.0,
      satFactor: 1.0 + _gaussian(random) * 0.03,
      vignetteAngle: pi / 120 + (_gaussian(random) + 1.0) / 2.0 * (pi / 80),
      zoomVal: 1.02 + (random.nextDouble() * 0.02),
      cropJitterX: 0.01 + random.nextDouble() * 0.02,
      cropJitterY: 0.01 + random.nextDouble() * 0.02,
      panStartX: random.nextDouble(),
      panStartY: random.nextDouble(),
      panEndX: random.nextDouble(),
      panEndY: random.nextDouble(),
      transitionDuration: 0.05 + random.nextDouble() * 0.05, // 0.05 - 0.10s
      lutFilePath: config.generateColorFilter ? await LutAssetProvider.extractRandom(random, ctx.tempDir.path) : null,
      gammaR: !config.generateColorFilter ? 0.98 + random.nextDouble() * 0.04 : null,
      gammaG: !config.generateColorFilter ? 0.98 + random.nextDouble() * 0.04 : null,
      gammaB: !config.generateColorFilter ? 0.98 + random.nextDouble() * 0.04 : null,
    );

    final plan = ctx.videoPlans[index]!;
    final segmentsToMerge = <String>[];
    final segmentDurations = <double>[];
    for (final r in plan) {
      final path = ctx.segmentFileMap[r];
      if (path != null) {
        segmentsToMerge.add(path);
        segmentDurations.add(r.duration);
      }
    }

    final ambientPath = (ctx.tempAmbientAudioPaths.isNotEmpty && index - 1 < ctx.tempAmbientAudioPaths.length) ? ctx.tempAmbientAudioPaths[index - 1] : null;

    final hasCustomAudio = config.customAudioPath != null && config.customAudioPath!.isNotEmpty && File(config.customAudioPath!).existsSync();
    
    // Prepare text overlays
    final textPaths = <String>[];
    for (var i = 0; i < config.textOverlays.length; i++) {
      final file = File(p.join(ctx.tempDir.path, 'text_${index}_$i.png'));
      await file.writeAsBytes(config.textOverlays[i].bytes);
      textPaths.add(file.absolute.path);
    }

    return CompositionPlan(
      outputIndex: index,
      segmentPaths: segmentsToMerge,
      segmentDurations: segmentDurations,
      outputDir: ctx.outputDir,
      tempDir: ctx.tempDir.path,
      config: config,
      params: params,
      ambientAudioPath: ambientPath,
      textOverlayPaths: textPaths,
      hasCustomAudio: hasCustomAudio,
      hasAmbientAudio: ambientPath != null,
    );
  }

  double _gaussian(Random r) {
    return ((r.nextDouble() + r.nextDouble() + r.nextDouble()) / 3.0 - 0.5) * 2.0;
  }
}
