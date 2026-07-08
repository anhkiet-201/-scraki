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
import 'package:scraki/features/video_poster/data/services/batch_video/core/utils/lut_transformer.dart';
import '../../factory/video_batch_engine_factory.dart';

/// Orchestrates the entire batch video generation pipeline.
/// 
/// This pipeline is responsible for:
/// - Hardware discovery and engine initialization.
/// - Source video metadata analysis.
/// - Audio fetching.
/// - Segment planning and unique segment extraction.
/// - Final video rendering and composition.
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

  /// Starts the planning phase of the pipeline.
  /// 
  /// Initializes context, resolves hardware capabilities, probes video metadata,
  /// fetches ambient audio if requested, and generates the composition plans.
  @override
  Future<void> plan({
    required List<String> sourceVideoPaths,
    required BatchVideoConfig config,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;

    _context = PipelineContext(config: config);
    _isContextInitialized = true;
    _eventController.add('Đang khởi tạo cấu hình mẻ render...');

    final ctx = _context;
    
    await _hardwareResolver.resolve();
    ctx.engine = VideoBatchEngineFactory.createEngine(
      _hardwareResolver,
      _metadataAnalyzer,
    );
    await ctx.engine.initialize();

    ctx.gpuInfo = _hardwareResolver.gpuInfo!;
    _eventController.add(
      'Phần cứng xử lý: ${ctx.gpuInfo.name} | Luồng: ${ctx.gpuInfo.maxConcurrentEncodes}',
    );

    _eventController.add('Đang kiểm tra metadata video nguồn...');
    final probeResults = await Future.wait(
      sourceVideoPaths.map((path) => _metadataAnalyzer.probeSourceVideo(path)),
    );

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

    if (config.generateAmbientAudio && config.outputOption != BatchVideoOutputOption.tiktokAutocutSet) {
      _eventController.add('Đang tải tài nguyên âm thanh...');
      try {
        final paths = await _ambientAudioProvider.fetchRandomAmbientAudios(
          config.outputCount,
          config.ambientTags,
          onLog: (msg) => _eventController.add(msg),
        );
        _context.tempAmbientAudioPaths.addAll(paths);
      } catch (e) {
        _eventController.add('⚠️ Lỗi tải ambient audio: $e');
      }
    }

    _eventController.add('Đang lập bản vẽ cắt ghép video...');
    _generatePlanning(config);
  }

  /// Prepares the output directory for the final generated videos.
  Future<void> _prepareOutputDir(PipelineContext ctx) async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('T', '_')
        .substring(0, 15);
    String baseOutputDir;
    if (ctx.config.outputDir != null) {
      baseOutputDir = ctx.config.outputDir!;
    } else {
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'];
          baseOutputDir =
              (userProfile != null &&
                  await Directory(p.join(userProfile, 'Desktop')).exists())
              ? p.join(userProfile, 'Desktop')
              : p.join(documentsDir.parent.path, 'Desktop');
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

    ctx.outputDir = p.join(baseOutputDir, 'output_vids_$timestamp');
    await Directory(ctx.outputDir).create(recursive: true);
  }

  /// Bypasses temporary extraction and renders segments directly to the output directory,
  /// specifically designed for the TikTok Autocut Set option.
  Future<void> _executeDirectCutForAutocutSet(PipelineContext ctx) async {
    _eventController.add('Đang phân xuất trực tiếp các luồng segments...');
    
    final activeTasks = <Future<void>>[];
    int completed = 0;
    int failed = 0;
    final maxConcurrent = ctx.gpuInfo.maxConcurrentEncodes;
    
    int totalSegments = ctx.videoPlans.values.fold(0, (sum, plan) => sum + plan.length);

    for (var entry in ctx.videoPlans.entries) {
      if (ctx.cancelled) break;
      
      final i = entry.key;
      final plan = entry.value;
      
      final String idxStr = i.toString().padLeft(3, '0');
      final String setDir = p.join(ctx.outputDir, 'tik_set_autocut_$idxStr');
      await Directory(setDir).create(recursive: true);
      
      for (int s = 0; s < plan.length; s++) {
        if (ctx.cancelled) break;
        
        while (activeTasks.length >= maxConcurrent) {
          await Future.any(List.from(activeTasks));
        }
        
        final req = plan[s];
        final String sIdxStr = (s + 1).toString().padLeft(2, '0');
        final outputPath = p.join(setDir, 'segment_$sIdxStr.mp4');
        
        late Future<void> task;
        task = ctx.engine
            .cutSegment(
              request: req,
              outputPath: outputPath,
              context: ctx.executionContext,
              timeout: const Duration(minutes: 5),
            )
            .then((result) {
              if (_context != ctx) return;
              if (result.success) {
                completed++;
                final pct = (completed / totalSegments * 100).toStringAsFixed(0);
                _eventController.add('_PROGRESS_LAZY: ⏳ Đang cắt: $pct% ($completed/$totalSegments)');
              } else {
                failed++;
                _eventController.add('⚠️ Lỗi cắt segment ${req.id}: ${result.logs}');
                if (failed > 5 && failed > totalSegments * 0.2) {
                  _eventController.add('❌ Quá nhiều lỗi trích xuất. Đang tự động dừng...');
                  cancel();
                }
              }
            }).catchError((Object error) {
              if (_context != ctx) return;
              failed++;
              _eventController.add('❌ Lỗi ngoại lệ khi cắt segment ${req.id}: $error');
              if (failed > 5) cancel();
            }).whenComplete(() {
              activeTasks.remove(task);
            });
            
        activeTasks.add(task);
      }
    }
    
    if (activeTasks.isNotEmpty) await Future.wait(List.from(activeTasks));
  }

  /// Extracts all unique segments across all generated plans into a temporary directory.
  @override
  Future<void> executeCutSegments() async {
    if (!_isContextInitialized || _context.cancelled) return;
    final ctx = _context;

    await _prepareOutputDir(ctx);

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    ctx.tempDir = Directory(
      p.join(Directory.systemTemp.path, 'scraki_segments_$timestamp'),
    );
    await ctx.tempDir.create(recursive: true);

    if (ctx.config.outputOption == BatchVideoOutputOption.tiktokAutocutSet) {
      return _executeDirectCutForAutocutSet(ctx);
    }

    _eventController.add('Đang bóc tách ${ctx.allUniqueSegments.length} segments...');

    final activeTasks = <Future<void>>[];
    int completed = 0;
    int failed = 0;
    final maxConcurrent = ctx.gpuInfo.maxConcurrentEncodes;

    for (final req in ctx.allUniqueSegments) {
      if (ctx.cancelled) break;
      
      while (activeTasks.length >= maxConcurrent) {
        await Future.any(List.from(activeTasks));
      }

      final outputPath = p.join(ctx.tempDir.path, '${req.id}.mp4');
      ctx.segmentFileMap[req] = outputPath;

      late Future<void> task;
      task = ctx.engine
          .cutSegment(
            request: req,
            outputPath: outputPath,
            context: ctx.executionContext,
            timeout: const Duration(minutes: 5),
          )
          .then((result) {
            if (_context != ctx) return;
            if (result.success) {
              completed++;
              final pct = (completed / ctx.allUniqueSegments.length * 100).toStringAsFixed(0);
              _eventController.add('_PROGRESS_LAZY: ⏳ Đang cắt: $pct% ($completed/${ctx.allUniqueSegments.length})');
            } else {
              failed++;
              _eventController.add('⚠️ Lỗi cắt segment ${req.id}: ${result.logs}');
              if (failed > 5 && failed > ctx.allUniqueSegments.length * 0.2) {
                _eventController.add('❌ Quá nhiều lỗi trích xuất. Đang tự động dừng...');
                cancel();
              }
            }
          }).catchError((Object error) {
            if (_context != ctx) return;
            failed++;
            _eventController.add('❌ Lỗi ngoại lệ khi cắt segment ${req.id}: $error');
            if (failed > 5) cancel();
          }).whenComplete(() {
            activeTasks.remove(task);
          });

      activeTasks.add(task);
    }

    if (activeTasks.isNotEmpty) await Future.wait(List.from(activeTasks));
  }

  /// Composes and renders the final videos based on the extracted segments.
  @override
  Future<void> executeRender() async {
    if (!_isContextInitialized || _context.cancelled) {
      _isProcessing = false;
      return;
    }
    final ctx = _context;

    _eventController.add('[3/3] Đang ghép ${ctx.config.outputCount} videos...');

    final activeTasks = <Future<void>>[];
    final maxConcurrent = ctx.gpuInfo.maxConcurrentEncodes;

    for (int i = 1; i <= ctx.config.outputCount; i++) {
      if (ctx.cancelled) break;
      
      while (activeTasks.length >= maxConcurrent) {
        await Future.any(List.from(activeTasks));
      }
      
      final plan = await _generateCompositionPlan(ctx, i);

      if (ctx.config.outputOption == BatchVideoOutputOption.tiktokAutocutSet) {
        _eventController.add('_PROGRESS_VID$i: ✅ Hoàn tất bộ Autocut $i');
        _eventController.add('_PROGRESS_VID$i: [$i/${ctx.config.outputCount}] Đang xử lý: 100%');
        continue;
      }

      late Future<void> task;
      task = ctx.engine
          .renderVideo(
            plan: plan,
            context: ctx.executionContext,
            timeout: const Duration(minutes: 15),
            onProgress: (pct) {
              if (_context != ctx) return;
              final progress = (pct * 100).toStringAsFixed(0);
              _eventController.add(
                '_PROGRESS_VID$i: [$i/${ctx.config.outputCount}] Đang xử lý: $progress%',
              );
            },
          )
          .then((result) {
            if (_context != ctx) return;
            if (result.success) {
              _eventController.add('_PROGRESS_VID$i: ✅ Kết xuất thành công video $i');
            } else {
              logger.e('❌ Thất bại video $i: ${result.logs}');
              _eventController.add('_PROGRESS_VID$i: ❌ Lỗi kết xuất video $i');
            }
          }).catchError((Object error) {
            if (_context != ctx) return;
            _eventController.add('❌ Lỗi tiến trình render video $i: $error');
          }).whenComplete(() {
            activeTasks.remove(task);
          });

      activeTasks.add(task);
    }

    if (activeTasks.isNotEmpty) await Future.wait(List.from(activeTasks));
    _eventController.add('✅ Hoàn thành quy trình Pipeline.');
    _isProcessing = false;
  }

  /// Cancels all ongoing tasks and operations inside the pipeline.
  @override
  void cancel() {
    if (_isContextInitialized) {
      try {
        _context.cancel();
      } catch (_) {}
    }
    _isProcessing = false;
    _eventController.add('🛑 Đã tạm dừng chuỗi tác vụ.');
  }

  /// Cleans up any resources or temporary files created during the pipeline execution.
  @override
  Future<void> cleanup() async {
    if (_isContextInitialized) {
      try {
        if (await _context.tempDir.exists()) {
          await _context.tempDir.delete(recursive: true);
          _eventController.add('🧹 Giải phóng thư mục đệm thành công.');
        }
      } catch (e) {
        _eventController.add('⚠️ Lỗi xóa thư mục đệm: $e');
      }
    }
  }

  /// Generates the overarching mapping of generated videos to their required segments.
  void _generatePlanning(BatchVideoConfig config) {
    final random = Random();
    _context.validSourceVideos.shuffle(random);

    List<SegmentRequest> globalSegmentPool = _generateSegmentPool(
      _context.validSourceVideos,
      _context.videoDurations,
      _context.videoHasAudio,
      config,
      random,
    );

    if (globalSegmentPool.isEmpty) return;

    int poolIndex = 0;
    for (int i = 1; i <= config.outputCount; i++) {
      final targetDuration =
          config.minFinalDuration +
          random.nextInt(config.maxFinalDuration - config.minFinalDuration + 1);
      final selected = <SegmentRequest>[];
      double totalDuration = 0.0;
      String lastVideoPath = '';

      while (totalDuration < targetDuration && !_context.cancelled) {
        if (poolIndex >= globalSegmentPool.length) {
          globalSegmentPool = _generateSegmentPool(
            _context.validSourceVideos,
            _context.videoDurations,
            _context.videoHasAudio,
            config,
            random,
            isRetry: true,
          );
          poolIndex = 0;
        }

        int foundIndex = -1;
        for (
          int checked = 0;
          checked < min(15, globalSegmentPool.length - poolIndex);
          checked++
        ) {
          final candidate = globalSegmentPool[poolIndex + checked];
          if ((_context.validSourceVideos.length <= 1 ||
                  candidate.sourcePath != lastVideoPath) &&
              !selected.any(
                (s) =>
                    s.sourcePath == candidate.sourcePath &&
                    s.startTime == candidate.startTime,
              )) {
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

  /// Creates a pool of available segments parsed from the source videos.
  List<SegmentRequest> _generateSegmentPool(
    List<String> validVideos,
    Map<String, int> videoDurations,
    Map<String, bool> videoHasAudio,
    BatchVideoConfig config,
    Random random, {
    bool isRetry = false,
  }) {
    final pool = <SegmentRequest>[];
    for (final src in List<String>.from(validVideos)..shuffle(random)) {
      final srcDur = videoDurations[src]!.toDouble();
      double currentTime = (srcDur > config.minSegmentDuration + 2)
          ? random.nextDouble() * 2.0
          : 0.0;
      while (currentTime + config.minSegmentDuration <= srcDur) {
        double maxPossible = min(
          config.maxSegmentDuration.toDouble(),
          srcDur - currentTime,
        );
        if (maxPossible < config.minSegmentDuration) break;
        final segDur =
            config.minSegmentDuration +
            (random.nextDouble() * (maxPossible - config.minSegmentDuration));
        pool.add(
          SegmentRequest(
            sourcePath: src,
            startTime: currentTime,
            duration: segDur,
            hflip: random.nextDouble() < (isRetry ? 0.7 : 0.3),
            hasAudio: videoHasAudio[src] ?? false,
          ),
        );
        currentTime += segDur;
      }
    }
    return pool..shuffle(random);
  }

  /// Builds a [CompositionPlan] containing the specific configuration and paths
  /// needed for rendering a single video iteration.
  Future<CompositionPlan> _generateCompositionPlan(
    PipelineContext ctx,
    int index,
  ) async {
    final random = Random();
    final config = ctx.config;

    final isAutocutSet = config.outputOption == BatchVideoOutputOption.tiktokAutocutSet;

    String? lutFilePath;
    if (config.generateColorFilter && !isAutocutSet) {
      final extractedPath = await LutAssetProvider.extractRandom(random, ctx.tempDir.path);
      final intensity = 0.2 + random.nextDouble() * 0.6;
      final transformedPath = p.join(ctx.tempDir.path, 'lut_transformed_${index}_${DateTime.now().millisecondsSinceEpoch}.cube');
      await LutTransformer.transform(File(extractedPath), File(transformedPath), intensity);
      lutFilePath = transformedPath;
    }

    final params = CompositionParams(
      targetDuration:
          config.minFinalDuration +
          random.nextInt(config.maxFinalDuration - config.minFinalDuration + 1),
      pts: 0.99 + random.nextDouble() * 0.02,
      brightness: _gaussian(random) * 0.015,
      contrast: 1.0 + _gaussian(random) * 0.02,
      gopSize: 48 + random.nextInt(144),
      bFrames: [0, 2, 3][random.nextInt(3)],
      creationTime:
          '${DateTime.now().toUtc().toIso8601String().split('.').first}.000000Z',
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
      transitionDuration: 0.05 + random.nextDouble() * 0.05,
      lutFilePath: lutFilePath,
      gammaR: !config.generateColorFilter
          ? 0.98 + random.nextDouble() * 0.04
          : null,
      gammaG: !config.generateColorFilter
          ? 0.98 + random.nextDouble() * 0.04
          : null,
      gammaB: !config.generateColorFilter
          ? 0.98 + random.nextDouble() * 0.04
          : null,
    );

    if (!ctx.videoPlans.containsKey(index)) {
      throw Exception('Video plan for index $index not found (Pipeline may have been cancelled)');
    }
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

    final ambientPath =
        (!isAutocutSet &&
            ctx.tempAmbientAudioPaths.isNotEmpty &&
            index - 1 < ctx.tempAmbientAudioPaths.length)
        ? ctx.tempAmbientAudioPaths[index - 1]
        : null;

    final hasCustomAudio =
        !isAutocutSet &&
        config.customAudioPath != null &&
        config.customAudioPath!.isNotEmpty &&
        File(config.customAudioPath!).existsSync();

    final textPaths = <String>[];
    if (!isAutocutSet) {
      for (var i = 0; i < config.textOverlays.length; i++) {
        final file = File(p.join(ctx.tempDir.path, 'text_${index}_$i.png'));
        await file.writeAsBytes(config.textOverlays[i].bytes);
        textPaths.add(file.absolute.path);
      }
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
    return ((r.nextDouble() + r.nextDouble() + r.nextDouble()) / 3.0 - 0.5) *
        2.0;
  }
}
