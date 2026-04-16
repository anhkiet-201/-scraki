import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:scraki/features/video_poster/domain/entities/custom_image_overlay.dart';
import 'package:scraki/features/video_poster/data/services/ambient_audio_service.dart';

// ============================================================================
// BatchVideoService — Cross-platform Dart reimplementation of make-vid.sh
// Works on macOS & Windows by calling ffmpeg/ffprobe via dart:io Process.
// ============================================================================

class TimedOverlay {
  final Uint8List bytes;
  final double startTime;
  final double? endTime;
  final bool isAnimated;
  final String animationInType;
  final double animationInDuration;
  final String animationOutType;
  final double animationOutDuration;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  const TimedOverlay({
    required this.bytes,
    required this.startTime,
    this.endTime,
    this.isAnimated = false,
    this.animationInType = 'none',
    this.animationInDuration = 0.1,
    this.animationOutType = 'none',
    this.animationOutDuration = 0.1,
    this.x = 0.5,
    this.y = 0.5,
    this.width = 0.0,
    this.height = 0.0,
    this.rotation = 0.0,
  });
}

/// Configuration constants matching make-vid.sh defaults.
class BatchVideoConfig {
  final int minSegmentDuration; // seconds
  final int maxSegmentDuration; // seconds
  final int minVideoDuration; // minimum source video length to be valid
  final int minFinalDuration; // seconds
  final int maxFinalDuration; // seconds
  final int outputCount;
  final String? outputDir; // null = auto-generate with timestamp
  final List<TimedOverlay> textOverlays;
  final List<CustomImageOverlay> imageOverlays;

  /// Đường dẫn file audio tùy chỉnh để mix vào video.
  /// null = chỉ dùng audio gốc (giảm về 5%).
  final String? customAudioPath;

  /// Âm lượng của nhạc tùy chỉnh (0.0 – 1.0).
  /// Mặc định 0.8 (~80%). Audio gốc sẽ được giữ ở 5%.
  final double customAudioVolume;

  /// Enable ambient audio (tiếng ồn trắng như chim, suối, mưa)
  final bool generateAmbientAudio;

  /// Bật filter sinh trộn màu ngẫu nhiên (chống re-up)
  final bool generateColorFilter;

  /// Các từ khoá để tìm kiếm âm thanh nền trên Freesound
  final List<String> ambientTags;

  const BatchVideoConfig({
    this.minSegmentDuration = 4,
    this.maxSegmentDuration = 6,
    this.minVideoDuration = 3,
    this.minFinalDuration = 35,
    this.maxFinalDuration = 45,
    this.outputCount = 10,
    this.outputDir,
    this.textOverlays = const [],
    this.imageOverlays = const [],
    this.customAudioPath,
    this.customAudioVolume = 0.8,
    this.generateAmbientAudio = true,
    this.generateColorFilter = true,
    this.ambientTags = const [
      'forest birds', 'river stream', 'rain drops', 'wind through trees', 
      'ocean waves', 'crickets chirping', 'distant thunder', 'waterfall ambient',
      'night forest', 'breeze leaves', 'jungle ambience', 'field recording nature'
    ],
  });
}

class BatchVideoService {
  // ─── Cross-platform binaries ──────────────────────────────────────────────

  static String get _ffmpegBin => Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';

  static String get _ffprobeBin =>
      Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';

  // ─── Opt-2: GPU encoder — resolved once per service instance ─────────────

  String? _cachedGpuEncoder;

  Future<String> _getGpuEncoder() async {
    return _cachedGpuEncoder ??= await _resolveGpuEncoder();
  }

  Future<String> _resolveGpuEncoder() async {
    if (Platform.isMacOS) return 'h264_videotoolbox';
    if (Platform.isWindows) {
      final encoders = await _getAvailableEncoders();
      if (encoders.contains('h264_nvenc')) return 'h264_nvenc';
      if (encoders.contains('h264_amf')) return 'h264_amf';
      if (encoders.contains('h264_qsv')) return 'h264_qsv';
    }
    return 'libx264';
  }

  List<String>? _availableEncoders;

  Future<List<String>> _getAvailableEncoders() async {
    if (_availableEncoders != null) return _availableEncoders!;
    try {
      final result = await Process.run(_ffmpegBin, ['-encoders']);
      final output = result.stdout as String;
      _availableEncoders =
          output
              .split('\n')
              .where((l) => l.contains('V....D'))
              .map((l) => l.split(' ').where((s) => s.isNotEmpty).skip(1).first)
              .toList();
      return _availableEncoders!;
    } catch (_) {
      return [];
    }
  }

  // ─── Opt-1: Color info cache — avoid re-probing the same source file ──────

  final Map<String, ({String transfer, String primaries, String pixFmt})>
  _colorInfoCache = {};


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
    _cachedGpuEncoder = null;
    _colorInfoCache.clear();

    final tempAmbientAudioPaths = <String>[];

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
        final documentsDir = await getApplicationDocumentsDirectory();
        
        if (Platform.isWindows) {
          // On Windows, Desktop is usually a sibling of Documents in the User profile
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
          // macOS/Linux
          baseOutputDir = p.join(documentsDir.parent.path, 'Desktop');
        }

        // Double check if desktop exists
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

      // Opt-1: probe duration + color info concurrently for all sources
      final probeResults = await Future.wait(
        sourceVideoPaths.map((path) => _probeSourceVideo(path)),
      );

      final validVideos = <String>[];
      final videoDurations = <String, int>{};
      final videoHasAudio = <String, bool>{};

      for (int i = 0; i < sourceVideoPaths.length; i++) {
        if (_cancelled) return;
        final path = sourceVideoPaths[i];
        final duration = probeResults[i].duration;
        if (duration >= config.minVideoDuration) {
          validVideos.add(path);
          videoDurations[path] = duration;
          videoHasAudio[path] = probeResults[i].hasAudio;
          // Warm up the color cache with the probe result (no extra ffprobe needed)
          _colorInfoCache[path] = probeResults[i].colorInfo;
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
          final ambientSvc = AmbientAudioService();
          final paths = await ambientSvc.fetchRandomAmbientAudios(
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

      List<_SegmentRequest> globalSegmentPool = _generateSegmentPool(
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
          // Trộn lại bài nếu đã xài cạn kiệt Pool
          if (poolIndex >= globalSegmentPool.length) {
            // Thay vì chỉ shuffle, chúng ta băm lại toàn bộ Pool để thay đổi Timeline
            globalSegmentPool = _generateSegmentPool(
                validVideos: validVideos,
                videoDurations: videoDurations,
                videoHasAudio: videoHasAudio,
                config: config,
                random: random,
            );
            poolIndex = 0;
          }

          // Tiện ích: Tìm đoạn cắt cố gắng không chung source với video sát trước đó
          // Look-ahead 15 bước trong mảng để tìm thẻ phù hợp
          int foundIndex = -1;
          for (int checked = 0; checked < min(15, globalSegmentPool.length - poolIndex); checked++) {
             final candidate = globalSegmentPool[poolIndex + checked];
             
             // 1. Không trùng source file liền kề nhau (trừ khi chỉ cung cấp 1 video duy nhất)
             bool diffSource = (validVideos.length <= 1) || (candidate.sourcePath != lastVideoPath);
             
             // 2. Không lặp lại 1 cảnh NGAY TRONG CÙNG 1 video output (Tránh cảm giác tua lại 1 cảnh 2 lần)
             bool alreadyInVideo = selected.any((s) => s.sourcePath == candidate.sourcePath && s.startTime == candidate.startTime);
             
             if (diffSource && !alreadyInVideo) {
                foundIndex = poolIndex + checked;
                break;
             }
          }

          // Nếu tìm thấy một khung hình thỏa mãn ở tương lai, tráo nó lên vị trí vòng lặp hiện tại
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

      final segmentFileMap = <_SegmentRequest, String>{};
      final activeCutTasks = <Future<void>>{};
      int completedSegments = 0;
      final totalSegments = allUniqueSegments.length;

      // Tạo initial entry để _handleLogUpdate có thể track và update in-place
      onLog?.call('_PROGRESS_LAZY: ⏳ Đang render segments: 0/$totalSegments...');

      for (final req in allUniqueSegments) {
        if (_cancelled) break;

        while (activeCutTasks.length >= _maxConcurrentTasks) {
          await Future.any(activeCutTasks);
        }
        if (_cancelled) break;

        final outputPath = p.join(tempDir.path, '${req.id}.mp4');
        segmentFileMap[req] = outputPath;

        late Future<void> task;
        task =
            _runSegmentCut(
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
              // Dùng _PROGRESS_LAZY để update cùng 1 dòng thay vì thêm dòng mới
              onLog?.call(
                '_PROGRESS_LAZY: ⏳ Đang render segments: $completedSegments/$totalSegments...',
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
        
        // Pick tương ứng nếu mảng đủ file, hoặc null
        final ambientPath = (tempAmbientAudioPaths.isNotEmpty && i - 1 < tempAmbientAudioPaths.length) 
            ? tempAmbientAudioPaths[i - 1] 
            : null;

        late Future<void> taskFuture;
        taskFuture = _createOutputVideo(
          outputIndex: i,
          segments: segmentsToMerge,
          outputDir: outputDir,
          config: config,
          ambientAudioPath: ambientPath,
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
    _cancelled = true;
    final processes = List<Process>.from(_activeProcesses);
    _activeProcesses.clear();
    for (final process in processes) {
      try {
        if (Platform.isWindows) {
          process.kill();
        } else {
          // sigterm is gentler on Unix
          process.kill(ProcessSignal.sigterm);
        }
      } catch (_) {}
    }
  }

  // ─── Constants ────────────────────────────────────────────────────────────

  /// Opt-5: Cân bằng số tác vụ đồng thời dựa trên số nhân CPU thực tế.
  /// Giới hạn tối thiểu 2 và tối đa 6 để tránh quá tải I/O và nghẽn CPU.
  static int get _maxConcurrentTasks =>
      Platform.numberOfProcessors.clamp(2, 6);

  /// Phân rã video thành các đoạn cắt không trùng lặp (Non-overlapping)
  /// Có bổ sung Random Offset để đảm bảo tính độc nhất khung hình khi băm lại.
  List<_SegmentRequest> _generateSegmentPool({
    required List<String> validVideos,
    required Map<String, int> videoDurations,
    required Map<String, bool> videoHasAudio,
    required BatchVideoConfig config,
    required Random random,
  }) {
    final pool = <_SegmentRequest>[];
    for (final src in validVideos) {
      final srcDur = videoDurations[src]!;
      
      // Bổ sung Initial Offset từ 0-2 giây để điểm bắt đầu của chuỗi cắt luôn thay đổi
      int currentTime = (srcDur > config.minSegmentDuration + 2) 
          ? random.nextInt(3) 
          : 0;

      while (currentTime + config.minSegmentDuration <= srcDur) {
        int maxPossible = min(config.maxSegmentDuration, srcDur - currentTime);
        if (maxPossible < config.minSegmentDuration) break;

        final segDur = config.minSegmentDuration +
            random.nextInt(maxPossible - config.minSegmentDuration + 1);

        pool.add(_SegmentRequest(
          sourcePath: src,
          startTime: currentTime,
          duration: segDur,
          // Sử dụng Smart Hflip: 30% xác suất lách ngang giúp phá vỡ pHash mạnh hơn
          hflip: random.nextDouble() < 0.3,
          hasAudio: videoHasAudio[src] ?? false,
        ));
        currentTime += segDur;
      }
    }
    pool.shuffle(random);
    return pool;
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

  /// Opt-1: Probe duration + color info in a single ffprobe call.
  /// Kết hợp 2 lần gọi ffprobe thành 1 để giảm I/O overhead.
  Future<({int duration, bool hasAudio, ({String transfer, String primaries, String pixFmt}) colorInfo})>
  _probeSourceVideo(String path) async {
    // Check cache for color info
    if (_colorInfoCache.containsKey(path)) {
      // We still need duration, but we can reuse the color info if we have to.
    }

    try {
      final result = await Process.run(_ffprobeBin, [
        '-show_entries',
        'format=duration:stream=codec_type,color_transfer,color_primaries,pix_fmt,duration',
        '-of', 'default=noprint_wrappers=1:nokey=0',
        path,
      ]);
      final out = result.stdout as String;
      final err = result.stderr as String; // Fallback source

      double durationSec = 0;
      bool hasAudio = false;
      String transfer = 'unknown';
      String primaries = 'unknown';
      String pixFmt = 'unknown';

      // Parse output từng dòng
      for (final line in out.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('duration=')) {
          // Lấy duration cao nhất (từ format hoặc từ stream bất kỳ)
          final val = double.tryParse(trimmed.split('=').last.trim());
          if (val != null && val > durationSec) {
            durationSec = val;
          }
        } else if (trimmed.startsWith('codec_type=audio')) {
          hasAudio = true;
        } else if (trimmed.startsWith('color_transfer=')) {
          final val = trimmed.split('=').last.trim();
          if (val != 'unknown') transfer = val;
        } else if (trimmed.startsWith('color_primaries=')) {
          final val = trimmed.split('=').last.trim();
          if (val != 'unknown') primaries = val;
        } else if (trimmed.startsWith('pix_fmt=')) {
          final val = trimmed.split('=').last.trim();
          if (val != 'unknown' && pixFmt == 'unknown') {
            pixFmt = val; // ưu tiên lấy pix_fmt hợp lệ đầu tiên
          }
        }
      }

      // FALLBACK: Quét dữ liệu ffprobe báo cáo qua stderr (banner) nếu metadata file khuyết duration
      if (durationSec == 0) {
        final durationRegex = RegExp(r'Duration:\s*(\d+):(\d+):(\d+\.\d+)');
        final match = durationRegex.firstMatch(err);
        if (match != null) {
          final h = int.parse(match.group(1)!);
          final m = int.parse(match.group(2)!);
          final s = double.tryParse(match.group(3)!) ?? 0;
          durationSec = (h * 3600) + (m * 60) + s;
        }
      }

      final info = (
        duration: durationSec.round(),
        hasAudio: hasAudio,
        colorInfo: (transfer: transfer, primaries: primaries, pixFmt: pixFmt),
      );
      
      // Update cache
      _colorInfoCache[path] = info.colorInfo;
      
      return info;
    } catch (_) {
      return (
        duration: 0,
        hasAudio: false,
        colorInfo: (transfer: '', primaries: '', pixFmt: ''),
      );
    }
  }

  /// Segment cut: luôn encode để đảm bảo mỗi segment bắt đầu bằng I-frame mới.
  /// Stream copy bị bỏ vì random seek không đảm bảo I-frame alignment,
  /// dẫn đến artifact/lag tại điểm nối khi concat.
  Future<String?> _runSegmentCut({
    required String input,
    required int startSeconds,
    required int duration,
    required String output,
    required bool hflip,
    required bool hasAudio,
    String? processName,
    void Function(double)? onProgress,
    void Function(String)? onLogMsg,
  }) async {
    // Validate input exists
    if (!await File(input).exists()) {
      onLogMsg?.call('  ❌ [${processName ?? p.basename(input)}] Lỗi: Không tìm thấy file nguồn');
      return null;
    }

    // Dùng cache thay vì gọi ffprobe lại
    final probeResult = await _probeSourceVideo(input);
    final colorInfo = probeResult.colorInfo;
    final isHdr = _isHdr(transfer: colorInfo.transfer, pixFmt: colorInfo.pixFmt);

    return _runSegmentEncode(
      input: input,
      startSeconds: startSeconds,
      duration: duration,
      output: output,
      hflip: hflip,
      hasAudio: hasAudio,
      isHdr: isHdr,
      colorInfo: colorInfo,
      processName: processName,
      onProgress: onProgress,
      onLogMsg: onLogMsg,
    );
  }

  /// Encode segment với filter chain (hflip nếu cần / HDR tonemapping / Audio 5%).
  /// Luôn tạo I-frame mới ở đầu mỗi segment để đảm bảo concat mượt.
  Future<String?> _runSegmentEncode({
    required String input,
    required int startSeconds,
    required int duration,
    required String output,
    required bool hflip,
    required bool hasAudio,
    required bool isHdr,
    required ({String transfer, String primaries, String pixFmt}) colorInfo,
    String? processName,
    void Function(double)? onProgress,
    void Function(String)? onLogMsg,
  }) async {
    String baseFilter =
        'scale=1080:1920:force_original_aspect_ratio=increase,'
        'crop=1080:1920,'
        'fps=30';

    if (hflip) {
      baseFilter += ',hflip';
    }

    final vfFilter = isHdr
        ? '$baseFilter,'
              'zscale=t=linear:npl=100,'
              'format=gbrpf32le,'
              'zscale=p=bt709,'
              'tonemap=tonemap=hable:desat=0,'
              'zscale=t=bt709:m=bt709,'
              'format=yuv420p'
        : '$baseFilter,format=yuv420p';

    // Giữ nguyên audio gốc ở segment (không giảm volume ở đây).
    // Volume thực sự (50% hoặc 5%) chỉ được áp dụng một lần duy nhất
    // tại bước _createOutputVideo qua toOriginalAudioFilterChain.
    final afFilter = hasAudio ? 'aresample=44100' : 'anullsrc';

    final gpuEncoder = await _getGpuEncoder();

    // Attempt with preferred filter (HDR-aware if applicable)
    final result = await _runWithFilter(
      vfFilter,
      afFilter,
      gpuEncoder,
      input: input,
      startSeconds: startSeconds,
      duration: duration,
      output: output,
      processName: processName,
      onProgress: onProgress,
      onLogMsg: onLogMsg,
    );

    // If initial attempt failed (e.g. GPU error or zscale failure), retry with CPU fallback
    if (result == null && !_cancelled) {
      final fallbackEncoder = 'libx264';
      if (gpuEncoder != fallbackEncoder) {
        onLogMsg?.call(
          '  ⚠️ [${processName ?? p.basename(input)}] Encode GPU thất bại, thử fallback CPU...',
        );
        final fallbackFilter = isHdr ? '$baseFilter,format=yuv420p' : '$baseFilter,format=yuv420p';
        return _runWithFilter(
          fallbackFilter,
          afFilter,
          fallbackEncoder,
          input: input,
          startSeconds: startSeconds,
          duration: duration,
          output: output,
          processName: processName,
          onProgress: onProgress,
          onLogMsg: onLogMsg,
        );
      }
    }

    // If HDR tonemapping failed (e.g. zscale not available), retry with
    // simple SDR fallback — colors may be clipped but video will be created.
    if (result == null && isHdr && !_cancelled) {
      onLogMsg?.call(
        '  ⚠️ [${processName ?? p.basename(input)}] zscale tonemapping thất bại, thử fallback SDR...',
      );
      final fallbackFilter = '$baseFilter,format=yuv420p';
      return _runWithFilter(
        fallbackFilter,
        afFilter,
        gpuEncoder,
        input: input,
        startSeconds: startSeconds,
        duration: duration,
        output: output,
        processName: processName,
        onProgress: onProgress,
        onLogMsg: onLogMsg,
      );
    }

    return result;
  }

  Future<String?> _runWithFilter(
    String vf,
    String af,
    String encoder, {
    required String input,
    required int startSeconds,
    required int duration,
    required String output,
    String? processName,
    void Function(double)? onProgress,
    void Function(String)? onLogMsg,
  }) async {
    try {
      final List<String> args = [
        '-hide_banner',
        '-y',
        '-hwaccel',
        'auto',
        '-ss', startSeconds.toString(),
        '-fflags', '+genpts+igndts',
        '-i', input,
      ];

      if (af == 'anullsrc') {
        args.addAll(['-f', 'lavfi', '-i', 'anullsrc=r=44100:cl=stereo']);
      }

      args.addAll([
        '-t', duration.toString(),
        '-vf', vf,
      ]);

      if (af == 'anullsrc') {
        args.addAll([
          '-map', '0:v:0',
          '-map', '1:a:0',
          '-c:a', 'aac',
          '-shortest',
        ]);
      } else {
        args.addAll([
          '-af', af,
          '-c:a', 'aac',
        ]);
      }

      args.addAll([
        '-pix_fmt', 'yuv420p',
        '-colorspace', 'bt709',
        '-color_trc', 'bt709',
        '-color_primaries', 'bt709',
        '-c:v', encoder,
      ]);

      if (encoder == 'libx264') {
        args.addAll([
          '-preset', 'ultrafast',
          '-b:v', '10M',
          '-maxrate', '12M',
          '-bufsize', '20M',
        ]);
      } else if (encoder == 'h264_videotoolbox') {
        args.addAll([
          '-b:v', '10M',
          '-realtime', '1',
        ]);
      } else {
        args.addAll([
          '-b:v', '10M',
          '-maxrate', '12M',
          '-bufsize', '20M',
        ]);
      }

      args.addAll([
        '-movflags', '+faststart',
        '-avoid_negative_ts', 'make_zero',
        '-map_metadata', '-1',
        output,
      ]);

      final process = await Process.start(_ffmpegBin, args);
      _activeProcesses.add(process);

      final regex = RegExp(r'time=(\d{2}):(\d{2}):(\d{2}\.\d{2})');
      // Capture full stderr for error reporting
      final stderrList = <String>[];
      
      process.stderr.listen((data) {
        final out = String.fromCharCodes(data);
        
        // Keep last 10 lines for error reporting
        final lines = out.split('\n');
        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            stderrList.add(line);
            if (stderrList.length > 15) stderrList.removeAt(0);
          }
        }

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
        final errorLog = stderrList.join('\n');
        if (errorLog.isNotEmpty && !_cancelled) {
          onLogMsg?.call(
            '  ❌ [${processName ?? p.basename(input)}] FFmpeg lỗi (exit $exitCode):\n$errorLog',
          );
        }
        return null;
      }
      return output;
    } catch (e) {
      if (!_cancelled) {
        onLogMsg?.call(
          '  ❌ [${processName ?? p.basename(input)}] Exception: $e',
        );
      }
      return null;
    }
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

    // Write concat list to a temp file
    final concatFile = File(
      p.join(Directory.systemTemp.path, 'scraki_concat_${outputIndex}_${DateTime.now().millisecondsSinceEpoch}.txt'),
    );
    final buffer = StringBuffer();
    for (final seg in segments) {
      final absPath = File(seg).absolute.path.replaceAll('\\', '/');
      buffer.writeln("file '$absPath'");
    }
    await concatFile.writeAsString(buffer.toString());

    // ── Random anti-reup parameters ─────────────────────────────────────────
    // Tăng biên độ PTS (±3.5%) để phá vỡ temporal fingerprinting
    final pts = 0.965 + random.nextDouble() * 0.07;
    final brightness = (random.nextDouble() * 0.04) - 0.02;
    final contrast = 1.0 + (random.nextDouble() * 0.04) - 0.02;
    // Tăng độ nhiễu Noise (0.4 - 1.2) để ghi đè pHash cũ của bản gốc
    final noise = 0.4 + random.nextDouble() * 0.8;

    final spoofProfile = _VideoSpoofProfile.random(random);
    final gopSize = 30 + random.nextInt(31);

    final hasCustomAudio = config.customAudioPath != null &&
        config.customAudioPath!.isNotEmpty &&
        File(config.customAudioPath!).existsSync();
    final audioProfile = _AudioSpoofProfile.random(random);
    final noiseStr = noise.toStringAsFixed(2);
    final ptsStr = pts.toStringAsFixed(6);

    // Hue/Saturation jitter ±3°, ±3%
    final double hueShift = (random.nextDouble() * 6.0) - 3.0;
    final double satFactor = 0.97 + random.nextDouble() * 0.06;
    // Vignette angle ngẫu nhiên nhưng cực nhỏ (PI/100 -> PI/50) để không làm đen 4 góc
    final double vignetteAngle = pi / 100 + random.nextDouble() * (pi / 100);
    
    // Đổi Curves thành Gamma phân kênh (±2%) để chống perceptual hash.
    // Dùng Gamma thay vì Curves để tránh phải chuyển hệ màu sang 'gbrp' (Gây lỗi crash encoder trên Mac và rác log cảnh báo)
    final double gammaR = 0.98 + random.nextDouble() * 0.04;
    final double gammaG = 0.98 + random.nextDouble() * 0.04;
    final double gammaB = 0.98 + random.nextDouble() * 0.04;

    final finalOutput =
        '${Directory(outputDir).absolute.path}${Platform.pathSeparator}tik_final_${outputIndex.toString().padLeft(3, '0')}.mp4';

    final textOverlayFiles = <File>[];

    try {
      // Opt-2: dùng cached encoder thay vì await lại
      final gpuEncoder = await _getGpuEncoder();

      // hasCustomAudio được xác định trước try block để probe audio duration.

      final List<String> ffmpegArgs = [
        '-hide_banner',
        '-y',
        '-hwaccel',
        'auto',
        '-fflags',
        '+genpts',
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        concatFile.path,
      ];

      // Input 1 (optional): custom audio — ffmpeg sẽ trim theo video
      if (hasCustomAudio) {
        ffmpegArgs.addAll([
          '-i', config.customAudioPath!,
        ]);
      }

      final hasAmbientAudio = ambientAudioPath != null && File(ambientAudioPath).existsSync();
      if (hasAmbientAudio) {
        ffmpegArgs.addAll([
          '-stream_loop', '-1',
          '-i', ambientAudioPath,
        ]);
      }

      // custom audio chiếm 1 tham số, ambient chiếm 1 tham số bổ sung.
      final int externalAudioCount = (hasCustomAudio ? 1 : 0) + (hasAmbientAudio ? 1 : 0);

      // 1. Text Overlays (Timed)
      for (var i = 0; i < config.textOverlays.length; i++) {
        final overlay = config.textOverlays[i];
        final file = File(
          p.join(Directory.systemTemp.path, 'scraki_text_${outputIndex}_${i}_${DateTime.now().millisecondsSinceEpoch}.png'),
        );
        await file.writeAsBytes(overlay.bytes);
        textOverlayFiles.add(file);
        ffmpegArgs.addAll(['-loop', '1', '-i', file.absolute.path]);
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

      // 3. Build filter complex
      StringBuffer filterComplex = StringBuffer();

      // Opt-4: Crop tĩnh với offset ngẫu nhiên nhỏ trực tiếp trên tỷ lệ 1080x1920
      // Luôn render ra đúng 1080x1920 để Tiktok không tạo viền đen
      final double zoomVal = 1.02 + (random.nextDouble() * 0.02); // 1.02x - 1.04x để dư biên an toàn
      
      // Sử dụng flags=bicubic thay vì lanczos để tăng tốc độ xử lý pixel (nhanh hơn 2-3 lần)
      filterComplex.write(
        '[0:v]scale=\'if(gt(iw/ih,1080/1920),-1,1080*$zoomVal)\':\'if(gt(iw/ih,1080/1920),1920*$zoomVal,-1)\':flags=bicubic,',
      );
      // Crop với offset ngẫu nhiên nhẹ dựa trên kích thước thật sau khi scale
      final double randX = random.nextDouble();
      final double randY = random.nextDouble();
      filterComplex.write('crop=1080:1920:(iw-1080)*$randX:(ih-1920)*$randY,');
      
      if (config.generateColorFilter) {
        final colorProfile = _ColorFilterProfile.random(random);
        filterComplex.write('colorchannelmixer=${colorProfile.ffmpegString},');
        final double gammaBase = 0.98 + random.nextDouble() * 0.04;
        filterComplex.write(
          'eq=brightness=${brightness.toStringAsFixed(4)}:contrast=${contrast.toStringAsFixed(4)}:gamma=${gammaBase.toStringAsFixed(3)},',
        );
      } else {
        filterComplex.write(
          'eq=brightness=${brightness.toStringAsFixed(4)}:contrast=${contrast.toStringAsFixed(4)}'
          ':gamma_r=${gammaR.toStringAsFixed(3)}:gamma_g=${gammaG.toStringAsFixed(3)}:gamma_b=${gammaB.toStringAsFixed(3)},',
        );
      }

      // Hue/saturation jitter để phá vỡ color histogram fingerprint
      filterComplex.write('hue=h=${hueShift.toStringAsFixed(2)}:s=${satFactor.toStringAsFixed(4)},');
      // Noise sẽ được gộp và áp dụng ở bước cuối cùng để tiết kiệm CPU
      // Vignette nhẹ tránh trùng mã điểm ảnh góc viền
    // Sử dụng flags=lanczos cho chất lượng scale cao nhưng cấu trúc pixel khác biệt
      filterComplex.write('vignette=${vignetteAngle.toStringAsFixed(4)},');
      filterComplex.write('trim=start=0,setpts=$ptsStr*N/30/TB[bg];');

      int overlayIdx = 1;
      String lastVideoLabel = '[bg]';

      // 3a. Overlay Custom Images
      // Input index: 0=concat video, [tiếp theo là các file external audio], sau đó text, sau đó images
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
          finalW = (targetW * cos(angle).abs() + targetH * sin(angle).abs())
              .round();
          finalH = (targetW * sin(angle).abs() + targetH * cos(angle).abs())
              .round();
        }

        final int targetX = (imgConfig.x * 1080 - finalW / 2).round();
        final int targetY = (imgConfig.y * 1920 - finalH / 2).round();

        // Tăng mạnh biên độ ngẫu nhiên cho Image Overlay để tránh Batch Detection
        final double overlayScale = 0.90 + (random.nextDouble() * 0.20); // ±10%
        final double overlayRotate = (random.nextDouble() * 6.0) - 3.0;  // ±3 độ
        final double overlayBright = (random.nextDouble() * 0.08) - 0.04; 
        final double overlaySat = 0.95 + (random.nextDouble() * 0.1); 
        final int jX = random.nextInt(61) - 30; // ±30px
        final int jY = random.nextInt(61) - 30; // ±30px

        final int finalTargetW = (targetW * overlayScale).round();
        final int finalTargetH = (targetH * overlayScale).round();

        String scaleLabel = '[scaled$overlayIdx]';
        String scaleFilter =
            '[$currentInputIdx:v]scale=$finalTargetW:$finalTargetH';
        scaleFilter +=
            ',format=rgba,eq=brightness=$overlayBright:saturation=$overlaySat';

        if (imgConfig.rotation != 0 || overlayRotate != 0) {
          final double totalRotation = imgConfig.rotation + overlayRotate;
          scaleFilter +=
              ',rotate=$totalRotation*PI/180:c=black@0:ow=$finalW:oh=$finalH';
        }
        if (imgConfig.borderWidth > 0) {
          final String borderHex = _colorToHex(imgConfig.borderColor ?? Colors.white);
          final int ffBorderW = (imgConfig.borderWidth * 1.5).round();
          scaleFilter += ',drawbox=c=$borderHex:t=$ffBorderW';
        }

        filterComplex.write('$scaleFilter$scaleLabel;');

        String enableFilter = "enable='between(t,${imgConfig.startTime},";
        if (imgConfig.endTime != null) {
          enableFilter += "${imgConfig.endTime})'";
        } else {
          enableFilter += "99999)'";
        }

        String nextVideoLabel = '[ov$overlayIdx]';
        String shortestFlag = imgConfig.isGif ? ':shortest=1' : '';
        filterComplex.write(
          '$lastVideoLabel$scaleLabel'
          'overlay=${targetX + jX}:${targetY + jY}:$enableFilter$shortestFlag$nextVideoLabel;',
        );

        lastVideoLabel = nextVideoLabel;
        overlayIdx++;
      }

      // 3b. Overlay Text
      for (int i = 0; i < config.textOverlays.length; i++) {
        final overlay = config.textOverlays[i];
        // Text input index: 1 (+ externalAudioCount nếu có) + i
        int textInputIdx = 1 + externalAudioCount + i;

        if (!overlay.isAnimated) {
          final int textJX = random.nextInt(51) - 25; // ±25px
          final int textJY = random.nextInt(51) - 25; // ±25px
          final double textOpacity = 0.90 + (random.nextDouble() * 0.10); // 0.9 - 1.0
          final double textRotate = (random.nextDouble() * 3.0) - 1.5;    // ±1.5 độ xoay nhẹ
          final double textScale = 0.97 + (random.nextDouble() * 0.06);   // ±3% scale

          String antiOcrLabel = '[static_aocr$i]';
          // Tinh giản bộ lọc Anti-OCR để giữ độ sắc nét "Premium"
          // Chỉ dùng Rotate, Scale và Noise cực nhẹ để phá vỡ hash mà không làm răng cưa viền
          filterComplex.write(
            '[$textInputIdx:v]scale=iw*$textScale:-1,format=rgba,'
            'rotate=$textRotate*PI/180:c=black@0,'
            'colorchannelmixer=aa=$textOpacity$antiOcrLabel;'
          );

          String enableFilter = "enable='between(t,${overlay.startTime},";
          if (overlay.endTime != null) {
            enableFilter += "${overlay.endTime})'";
          } else {
            enableFilter += "99999)'";
          }

          // Rung lắc vi mô ở mức tinh tế (±1px)
          final nextVideoLabel = '[ov$overlayIdx]';
          final driftX = '1.0*sin(2*PI*n/15)'; 
          final driftY = '1.0*cos(2*PI*n/15)';
          
          filterComplex.write(
            '$lastVideoLabel$antiOcrLabel'
            'overlay=x=\'$textJX+$driftX\':y=\'$textJY+$driftY\':$enableFilter:shortest=1$nextVideoLabel;'
          );

          lastVideoLabel = nextVideoLabel;
          overlayIdx++;
        } else {
          // --- Animated Text Logic ---
          // Dimensions and positioning
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
          
          if (overlay.rotation != 0) {
            filterBlock += ',rotate=${overlay.rotation}*PI/180:c=black@0:ow=$finalW:oh=$finalH';
          }

          final start = overlay.startTime;
          final end = overlay.endTime ?? 40.0;
          final totalDur = (end - start).abs();
          
          String xExprIn = '';
          String yExprIn = '';
          String xExprOut = '';
          String yExprOut = '';
          String scaleExpr = '1.0';
          // Build IN logic
          if (overlay.animationInType != 'none') {
            final durIn = totalDur * overlay.animationInDuration;
            if (overlay.animationInType == 'fade') {
              filterBlock += ',fade=t=in:st=$start:d=$durIn:alpha=1';
            } else if (overlay.animationInType == 'slideUp') {
              final int startY = targetY + 75;
              yExprIn = '$startY - 75*(t-$start)/$durIn';
            } else if (overlay.animationInType == 'slideDown') {
              final int startY = targetY - 75;
              yExprIn = '$startY + 75*(t-$start)/$durIn';
            } else if (overlay.animationInType == 'slideLeft') {
              final int startX = targetX + 75;
              xExprIn = '$startX - 75*(t-$start)/$durIn';
            } else if (overlay.animationInType == 'slideRight') {
              final int startX = targetX - 75;
              xExprIn = '$startX + 75*(t-$start)/$durIn';
            } else if (overlay.animationInType == 'zoom') {
              final endIn = start + durIn;
              scaleExpr = 'if(lt(t,$endIn),(t-$start)/$durIn,1.0)';
              xExprIn = '$centerX-w/2';
              yExprIn = '$centerY-h/2';
              filterBlock += ',fade=t=in:st=$start:d=$durIn:alpha=1';
            }
          }

          // Build OUT logic
          if (overlay.animationOutType != 'none' && totalDur > 0) {
            final durOut = totalDur * overlay.animationOutDuration;
            final startOut = end - durOut;
            if (overlay.animationOutType == 'fade') {
              filterBlock += ',fade=t=out:st=$startOut:d=$durOut:alpha=1';
            } else if (overlay.animationOutType == 'slideUp') {
              yExprOut = '$targetY-75*(t-$startOut)/$durOut';
            } else if (overlay.animationOutType == 'slideDown') {
              yExprOut = '$targetY+75*(t-$startOut)/$durOut';
            } else if (overlay.animationOutType == 'slideLeft') {
              xExprOut = '$targetX-75*(t-$startOut)/$durOut';
            } else if (overlay.animationOutType == 'slideRight') {
              xExprOut = '$targetX+75*(t-$startOut)/$durOut';
            } else if (overlay.animationOutType == 'zoom') {
              scaleExpr = 'if(gt(t,$startOut),1.0-(t-$startOut)/$durOut,$scaleExpr)';
              xExprOut = '$centerX-w/2';
              yExprOut = '$centerY-h/2';
              filterBlock += ',fade=t=out:st=$startOut:d=$durOut:alpha=1';
            }
          }
          
          if (scaleExpr != '1.0') {
            filterBlock += ",scale='bitand(iw*$scaleExpr,-2)':'bitand(ih*$scaleExpr,-2)':eval=frame";
          }

          // Combine X logic
          String finalXExpr = '$targetX';
          if (xExprIn.isEmpty && xExprOut.isNotEmpty) {
            final startOut = end - (totalDur * overlay.animationOutDuration);
            finalXExpr = 'if(gt(t\\,$startOut)\\,$xExprOut\\,$targetX)';
          } else if (xExprIn.isNotEmpty && xExprOut.isEmpty) {
            final endIn = start + (totalDur * overlay.animationInDuration);
            finalXExpr = 'if(lt(t\\,$endIn)\\,$xExprIn\\,$targetX)';
          } else if (xExprIn.isNotEmpty && xExprOut.isNotEmpty) {
            final endIn = start + (totalDur * overlay.animationInDuration);
            final startOut = end - (totalDur * overlay.animationOutDuration);
            finalXExpr = 'if(lt(t\\,$endIn)\\,$xExprIn\\,if(gt(t\\,$startOut)\\,$xExprOut\\,$targetX))';
          }

          // Combine Y logic
          String finalYExpr = '$targetY';
          if (yExprIn.isEmpty && yExprOut.isNotEmpty) {
            final startOut = end - (totalDur * overlay.animationOutDuration);
            finalYExpr = 'if(gt(t\\,$startOut)\\,$yExprOut\\,$targetY)';
          } else if (yExprIn.isNotEmpty && yExprOut.isEmpty) {
            final endIn = start + (totalDur * overlay.animationInDuration);
            finalYExpr = 'if(lt(t\\,$endIn)\\,$yExprIn\\,$targetY)';
          } else if (yExprIn.isNotEmpty && yExprOut.isNotEmpty) {
            final endIn = start + (totalDur * overlay.animationInDuration);
            final startOut = end - (totalDur * overlay.animationOutDuration);
            finalYExpr = 'if(lt(t\\,$endIn)\\,$yExprIn\\,if(gt(t\\,$startOut)\\,$yExprOut\\,$targetY))';
          }
          
          String xExpr = finalXExpr;
          String yExpr = finalYExpr;
          String antiOcrAnimLabel = '[anim_aocr$i]';
          
          // Anti-OCR tinh giản cho text anim
          filterComplex.write(
            '$filterBlock$antiOcrAnimLabel;'
          );

          String enableFilter = "enable='between(t,$start,$end)'";
          String nextVideoLabel = '[ov$overlayIdx]';
          
          // Rung lắc vi mô tinh tế cho text anim (±1px)
          final driftX = '1.0*sin(2*PI*n/20)';
          final driftY = '1.0*cos(2*PI*n/20)';

          filterComplex.write(
            '$lastVideoLabel$antiOcrAnimLabel'
            'overlay=x=\'$xExpr+$driftX\':y=\'$yExpr+$driftY\':$enableFilter:shortest=1$nextVideoLabel;'
          );

          lastVideoLabel = nextVideoLabel;
          overlayIdx++;
        }
      }

      // Final processing: Gộp bộ lọc Noise vào bước cuối cùng để tối ưu hiệu năng
      String consolidatedNoise = 'noise=alls=$noiseStr:allf=t';
      String fStr = filterComplex.toString();
      fStr += '$lastVideoLabel$consolidatedNoise[final_v];';
      lastVideoLabel = '[final_v]';

      // Build audio mix filter:
      String audioMapArg;
      int mixInputs = 1;

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
        // Ambient vol: 25% nếu có custom nhạc, 5% nếu không có
        final ambientVol = hasCustomAudio ? 0.25 : 0.05;
        final ambientInputIdx = hasCustomAudio ? 2 : 1;
        // Normalizer
        fStr += '[$ambientInputIdx:a]volume=${ambientVol.toStringAsFixed(3)},aresample=44100,aformat=channel_layouts=stereo[ambient_a];';
        mixLabels += '[ambient_a]';
      }

      if (mixInputs > 1) {
         fStr += '${mixLabels}amix=inputs=$mixInputs:duration=first:dropout_transition=0,'
                 'aresample=async=1:first_pts=0[mixed_a]';
         audioMapArg = '[mixed_a]';
      } else {
         fStr += '[orig_a]aresample=async=1:first_pts=0[final_orig_a]';
         audioMapArg = '[final_orig_a]';
      }

      if (fStr.endsWith(';')) fStr = fStr.substring(0, fStr.length - 1);

      ffmpegArgs.addAll([
        '-filter_complex',
        fStr,
        '-map',
        lastVideoLabel,
        '-map',
        audioMapArg,
        '-c:a',
        'aac',
        '-b:a', '${audioProfile.audioBitrate}k', // Audio bitrate jitter: 96/112/128/160 kbps
        '-r',
        '30',
        '-fps_mode',
        'cfr',
        '-c:v',
        gpuEncoder,
        '-b:v',
        '${10 + random.nextInt(6)}M', // Random 10M - 15M
        '-maxrate',
        '16M',
        '-bufsize',
        '25M',
        '-pix_fmt',
        'yuv420p',
        '-colorspace',
        'bt709',
        '-color_trc',
        'bt709',
        '-color_primaries',
        'bt709',
        // GOP jitter áp dụng cho tất cả encoders (không chỉ libx264)
        if (gpuEncoder == 'libx264') ...[
          '-x264-params',
          'profile=high:level=4.1:bframes=0:cabac=1:8x8dct=1:ref=1:g=$gopSize',
          '-preset',
          spoofProfile.preset,
        ] else ...[
          '-g', gopSize.toString(),
        ],
        '-map_metadata',
        '-1',
        '-movflags',
        '+faststart+use_metadata_tags',
        ...spoofProfile.toFfmpegMetadataArgs(),
        '-avoid_negative_ts',
        'make_zero', // Dập tắt mọi giá trị âm còn sót lại về 0 trước khi ghi file
        '-movflags', '+faststart+use_metadata_tags', // Đẩy moov atom lên đầu giống mobile phone
        '-shortest', // Đảm bảo video và audio kết thúc cùng lúc
        finalOutput,
      ]);

      final process = await Process.start(_ffmpegBin, ffmpegArgs);
      _activeProcesses.add(process);

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
        if (concatFile.existsSync()) await concatFile.delete();
      } catch (_) {}
      for (final file in textOverlayFiles) {
        try {
          if (file.existsSync()) await file.delete();
        } catch (_) {}
      }
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

  String _colorToHex(Color color) {
    return '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
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
  final bool hasAudio;

  _SegmentRequest({
    required this.sourcePath,
    required this.startTime,
    required this.duration,
    required this.hflip,
    required this.hasAudio,
  });

  String get id {
    final name = sourcePath.split(RegExp(r'[/\\]')).last;
    final hflipVal = hflip ? 1 : 0;
    final audioVal = hasAudio ? 1 : 0;
    return 's${startTime}_d${duration}_f${hflipVal}_a${audioVal}_$name';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SegmentRequest &&
          runtimeType == other.runtimeType &&
          sourcePath == other.sourcePath &&
          startTime == other.startTime &&
          duration == other.duration &&
          hflip == other.hflip &&
          hasAudio == other.hasAudio;

  @override
  int get hashCode =>
      sourcePath.hashCode ^
      startTime.hashCode ^
      duration.hashCode ^
      hflip.hashCode ^
      hasAudio.hashCode;
}

// ============================================================================
// _VideoSpoofProfile — per-video randomized metadata to avoid batch detection
// ============================================================================

/// Encapsulates all per-video spoofing parameters.
/// Call [_VideoSpoofProfile.random] to generate a fresh profile for each output.
class _VideoSpoofProfile {
  static const _devices = [
    (model: 'Samsung Galaxy S23 Ultra', android: '13'),
    (model: 'Samsung Galaxy S24 Ultra', android: '14'),
    (model: 'Samsung Galaxy Z Fold5', android: '13'),
    (model: 'Samsung Galaxy A54 5G', android: '13'),
    (model: 'Samsung Galaxy Tab S9 Ultra', android: '13'),
    (model: 'Google Pixel 8 Pro', android: '14'),
    (model: 'Google Pixel 7 Pro', android: '13'),
    (model: 'Google Pixel 6a', android: '13'),
    (model: 'Google Pixel Fold', android: '13'),
    (model: 'Xiaomi 13 Pro', android: '13'),
    (model: 'Xiaomi 14 Ultra', android: '14'),
    (model: 'Redmi Note 13 Pro+', android: '13'),
    (model: 'Xiaomi Pad 6', android: '13'),
    (model: 'Oppo Find X6 Pro', android: '13'),
    (model: 'Oppo Reno10 Pro+', android: '13'),
    (model: 'Oppo Find N3 Flip', android: '13'),
    (model: 'Vivo X90 Pro+', android: '13'),
    (model: 'Vivo V29 Pro', android: '13'),
    (model: 'Vivo X Flip', android: '13'),
    (model: 'Realme GT5', android: '13'),
    (model: 'Realme 11 Pro+', android: '13'),
    (model: 'Sony Xperia 1 V', android: '13'),
    (model: 'Sony Xperia 5 V', android: '13'),
    (model: 'OnePlus 11', android: '13'),
    (model: 'OnePlus 12', android: '14'),
    (model: 'OnePlus Open', android: '13'),
    (model: 'Motorola Edge 40 Pro', android: '13'),
    (model: 'Motorola Razr 40 Ultra', android: '13'),
    (model: 'Asus ROG Phone 7 Ultimate', android: '13'),
    (model: 'Asus Zenfone 10', android: '13'),
    (model: 'Nothing Phone (2)', android: '13'),
    (model: 'Nokia G42', android: '13'),
  ];

  static const _presets = ['ultrafast', 'superfast', 'veryfast'];

  /// GPS bounding box: TP.HCM + Bình Dương
  static const _latMin = 10.65;
  static const _latMax = 11.30;
  static const _lonMin = 106.55;
  static const _lonMax = 107.00;

  final String model;
  final String androidVersion;
  final String creationTime;
  final String gpsIso6709;
  final String preset;
  final String jitterId; // file-size jitter
  final String videoId; // UUID for CapCut

  const _VideoSpoofProfile({
    required this.model,
    required this.androidVersion,
    required this.creationTime,
    required this.gpsIso6709,
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
        '${recordedTime.toUtc().toIso8601String().split('.').first}.000000Z';

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
      androidVersion: device.android,
      creationTime: recordedAt,
      gpsIso6709: gps,
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
    'location=$gpsIso6709',
    '-metadata',
    'LvMetaInfo=$_lvMetaInfo',
    '-metadata',
    'comment=sc_v_$jitterId',
    // Giả lập Encoder của hệ thống Android thật (Gallery/Camera app)
    '-metadata',
    'encoder=com.android.gallery3d',
  ];
}

// ============================================================================
// _AudioSpoofProfile — per-video randomized audio transform params
// ============================================================================

/// Encapsulates tất cả tham số biến đổi audio để phá vỡ audio fingerprint
/// (pitch shift, EQ curve, time offset, bitrate jitter).
///
/// TikTok dùng spectral fingerprinting (tương tự ACRCloud) để nhận diện
/// cùng 1 bài nhạc ngay cả khi volume thay đổi. Class này đảm bảo mỗi
/// video xuất ra có audio signature khác nhau.
class _AudioSpoofProfile {
  /// Hệ số pitch (0.98 – 1.02): dịch pitch ±1 semitone.
  /// Kết hợp asetrate + atempo để giữ nguyên tốc độ phát.
  final double pitchFactor;

  /// EQ gain dải bass ~80Hz (±1.5 dB).
  final double bassGain;

  /// EQ gain dải mid ~1000Hz (±1.5 dB).
  final double midGain;

  /// EQ gain dải treble ~8000Hz (±1.5 dB).
  final double trebleGain;

  /// Audio bitrate kbps: 96 | 112 | 128 | 160.
  final int audioBitrate;

  /// Micro-delay 1–5ms: tạo sample-level difference trong waveform.
  final int delayMs;

  const _AudioSpoofProfile({
    required this.pitchFactor,
    required this.bassGain,
    required this.midGain,
    required this.trebleGain,
    required this.audioBitrate,
    required this.delayMs,
  });

  factory _AudioSpoofProfile.random(Random random) {
    return _AudioSpoofProfile(
      // Tăng độ lệch pitch (±1.5%) để qua mặt nhận diện vân tay âm thanh gắt gao
      pitchFactor: 0.985 + random.nextDouble() * 0.03,
      bassGain: (random.nextDouble() * 3.0) - 1.5,
      midGain: (random.nextDouble() * 3.0) - 1.5,
      trebleGain: (random.nextDouble() * 3.0) - 1.5,
      audioBitrate: [96, 112, 128, 160][random.nextInt(4)],
      delayMs: 1 + random.nextInt(5),
    );
  }

  /// Filter chain cho custom audio (nhạc nền).
  /// Bao gồm: pitch shift → EQ → volume → sync với tốc độ video.
  String toCustomAudioFilterChain({required double volume, required double pts}) {
    final pitchStr = pitchFactor.toStringAsFixed(6);
    // Tính toán tempo tổng hợp:
    // tempo = (1 / pitchFactor) * (1 / pts)
    // - (1 / pitchFactor): để giữ nguyên tốc độ sau khi asetrate thay đổi pitch.
    // - (1 / pts): để đồng bộ tốc độ audio với thay đổi setpts của video.
    final totalTempo = (1.0 / (pitchFactor * pts)).clamp(0.5, 2.0).toStringAsFixed(6);

    final volStr = volume.toStringAsFixed(3);
    // [Iron Fist]
    // 1. aresample=44100: Ép về 44.1k chuẩn.
    // 2. atrim=start=0: Vứt bỏ triệt để mọi mẫu âm thanh có timestamp âm.
    // 3. asetrate=44100*pitch: Thay đổi tốc độ lấy mẫu để đổi Pitch.
    // 4. atempo: Điều chỉnh lại tốc độ phát (tempo) để đồng bộ video jitter.
    // 5. asetpts=PTS-STARTPTS: Đảm bảo timeline bắt đầu sạch từ 0 cho luồng này.
    // 6. aresample=44100:cl=stereo: Chuẩn hóa Stereo và sample rate trước khi vào amix.
    return 'aresample=44100,'
        'atrim=start=0,'
        'asetrate=44100*$pitchStr,'
        'atempo=$totalTempo,'
        'equalizer=f=80:width_type=o:width=2:g=${bassGain.toStringAsFixed(2)},'
        'equalizer=f=1000:width_type=o:width=2:g=${midGain.toStringAsFixed(2)},'
        'equalizer=f=8000:width_type=o:width=2:g=${trebleGain.toStringAsFixed(2)},'
        'adelay=$delayMs|$delayMs,'
        'volume=$volStr,'
        'asetpts=PTS-STARTPTS,'
        'aresample=44100,aformat=channel_layouts=stereo';
  }

  /// Filter chain cho original audio (audio gốc từ video).
  /// [volume]: mức âm lượng mong muốn (0.0–1.0).
  ///   - 0.25 (25%) khi có custom audio (người xem vẫn nghe được tiếng gốc dịu nhẹ).
  ///   - 0.05 (5%) khi không có custom audio (tiếng gốc rất nhỏ, tránh bị nhận diện).
  String toOriginalAudioFilterChain({required double volume, required double pts}) {
    final pitchStr = pitchFactor.toStringAsFixed(6);
    final totalTempo = (1.0 / (pitchFactor * pts)).clamp(0.5, 2.0).toStringAsFixed(6);
    final volStr = volume.clamp(0.0, 1.0).toStringAsFixed(3);

    return 'aresample=44100,'
        'atrim=start=0,'
        'asetrate=44100*$pitchStr,'
        'atempo=$totalTempo,'
        'equalizer=f=80:width_type=o:width=2:g=${bassGain.toStringAsFixed(2)},'
        'equalizer=f=1000:width_type=o:width=2:g=${midGain.toStringAsFixed(2)},'
        'equalizer=f=8000:width_type=o:width=2:g=${trebleGain.toStringAsFixed(2)},'
        'adelay=$delayMs|$delayMs,'
        'volume=$volStr,'
        'asetpts=PTS-STARTPTS,'
        'aresample=44100,aformat=channel_layouts=stereo';
  }
}

// ============================================================================
// _ColorFilterProfile — per-video randomized color signature
// ============================================================================

class _ColorFilterProfile {
  final String ffmpegString;

  const _ColorFilterProfile._(this.ffmpegString);

  factory _ColorFilterProfile.random(Random random) {
    final type = random.nextInt(11);
    
    // Hệ số cường độ cực nhẹ (tương đương 10-15% opacity của filter) 
    // Độ lệch chuẩn chỉ từ ±0.01 đến ±0.04 so với Ma trận gốc (Identity Matrix)
    switch (type) {
      case 0: // Warm Tint (Red boost, Blue cut)
        final rBoost = 1.01 + random.nextDouble() * 0.02; // max +3%
        final bCut = 0.97 + random.nextDouble() * 0.02;   // max -3%
        return _ColorFilterProfile._('rr=${rBoost.toStringAsFixed(3)}:bb=${bCut.toStringAsFixed(3)}');
        
      case 1: // Cool Tint (Blue boost, Red cut)
        final bBoost = 1.01 + random.nextDouble() * 0.02;
        final rCut = 0.97 + random.nextDouble() * 0.02;
        return _ColorFilterProfile._('rr=${rCut.toStringAsFixed(3)}:bb=${bBoost.toStringAsFixed(3)}');
        
      case 2: // Vintage/Sepia (Slight R+G mix, B cut)
        final mix = 0.01 + random.nextDouble() * 0.01;
        return _ColorFilterProfile._('rr=${(1.0 + mix).toStringAsFixed(3)}:rg=${mix.toStringAsFixed(3)}:gg=${(1.0 + mix).toStringAsFixed(3)}:bb=${(0.98 - mix).toStringAsFixed(3)}');
        
      case 3: // Cinematic Green (Shadow green mix)
        final gBoost = 1.01 + random.nextDouble() * 0.02;
        final mix = 0.01 + random.nextDouble() * 0.01;
        return _ColorFilterProfile._('rb=${mix.toStringAsFixed(3)}:gg=${gBoost.toStringAsFixed(3)}:br=${mix.toStringAsFixed(3)}');
        
      case 4: // Cyberpunk/Pink (Red & Blue boost, Green cut)
        final rBoost = 1.01 + random.nextDouble() * 0.02;
        final bBoost = 1.01 + random.nextDouble() * 0.02;
        final gCut = 0.97 + random.nextDouble() * 0.02;
        return _ColorFilterProfile._('rr=${rBoost.toStringAsFixed(3)}:gg=${gCut.toStringAsFixed(3)}:bb=${bBoost.toStringAsFixed(3)}');

      case 5: // Twilight/Purple
        final mix = 0.01 + random.nextDouble() * 0.01;
        return _ColorFilterProfile._('rr=${(1.0 + mix).toStringAsFixed(3)}:rb=${mix.toStringAsFixed(3)}:gg=0.99:gb=${mix.toStringAsFixed(3)}:bb=${(1.01 + mix).toStringAsFixed(3)}');

      case 6: // Autumn/Orange
        final rBoost = 1.02 + random.nextDouble() * 0.02;
        final mix = 0.01 + random.nextDouble() * 0.01;
        return _ColorFilterProfile._('rr=${rBoost.toStringAsFixed(3)}:gr=${mix.toStringAsFixed(3)}:bb=0.97');

      case 7: // Matrix Green (Pure green boost)
        final gBoost = 1.02 + random.nextDouble() * 0.02;
        final cut = 0.97 + random.nextDouble() * 0.02;
        return _ColorFilterProfile._('rr=${cut.toStringAsFixed(3)}:gg=${gBoost.toStringAsFixed(3)}:bb=${cut.toStringAsFixed(3)}');

      case 8: // Gold/Amber
        final boost = 1.01 + random.nextDouble() * 0.02;
        final mix = 0.01 + random.nextDouble() * 0.01;
        return _ColorFilterProfile._('rr=${boost.toStringAsFixed(3)}:rg=${mix.toStringAsFixed(3)}:gg=${boost.toStringAsFixed(3)}:bb=0.97');

      case 9: // Muted/Bleach Bypass (Slight desat cross-mix)
        final m = 0.01 + random.nextDouble() * 0.01;
        final b = 0.98 - random.nextDouble() * 0.01;
        return _ColorFilterProfile._('rr=${b.toStringAsFixed(3)}:rg=${m.toStringAsFixed(3)}:rb=${m.toStringAsFixed(3)}:gr=${m.toStringAsFixed(3)}:gg=${b.toStringAsFixed(3)}:gb=${m.toStringAsFixed(3)}:br=${m.toStringAsFixed(3)}:bg=${m.toStringAsFixed(3)}:bb=${b.toStringAsFixed(3)}');

      default: // Random Micro-Jitter (Case 10)
        return _ColorFilterProfile._(
          'rr=${(0.98 + random.nextDouble() * 0.04).toStringAsFixed(3)}:'
          'rg=${((random.nextDouble() * 0.02) - 0.01).toStringAsFixed(3)}:'
          'rb=${((random.nextDouble() * 0.02) - 0.01).toStringAsFixed(3)}:'
          'gr=${((random.nextDouble() * 0.02) - 0.01).toStringAsFixed(3)}:'
          'gg=${(0.98 + random.nextDouble() * 0.04).toStringAsFixed(3)}:'
          'gb=${((random.nextDouble() * 0.02) - 0.01).toStringAsFixed(3)}:'
          'br=${((random.nextDouble() * 0.02) - 0.01).toStringAsFixed(3)}:'
          'bg=${((random.nextDouble() * 0.02) - 0.01).toStringAsFixed(3)}:'
          'bb=${(0.98 + random.nextDouble() * 0.04).toStringAsFixed(3)}'
        );
    }
  }
}
