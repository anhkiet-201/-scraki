import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:scraki/features/video_poster/domain/entities/image_poster_config.dart';

class SlideOverlayData {
  final Uint8List bytes;
  final String slideId;

  const SlideOverlayData({required this.bytes, required this.slideId});
}

class _StealthProfile {
  final double brightness;
  final double contrast;
  final double saturation;
  final double hue;
  final double noise;
  final int cropOffsetX;
  final int cropOffsetY;
  final int extraScale;
  final String creationTime;
  final String make;
  final String model;

  _StealthProfile({
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.hue,
    required this.noise,
    required this.cropOffsetX,
    required this.cropOffsetY,
    required this.extraScale,
    required this.creationTime,
    required this.make,
    required this.model,
  });

  factory _StealthProfile.random(Random rng) {
    // Randomize date within last 7 days
    final now = DateTime.now();
    final randomDays = rng.nextInt(7);
    final randomHours = rng.nextInt(24);
    final randomMinutes = rng.nextInt(60);
    final fakeDate = now.subtract(
      Duration(days: randomDays, hours: randomHours, minutes: randomMinutes),
    );

    // EXIF format: YYYY:MM:DD HH:MM:SS
    final dateStr = fakeDate
        .toIso8601String()
        .split('.')
        .first
        .replaceFirst('T', ' ')
        .replaceAll('-', ':');

    final devices = [
      {
        'make': 'Samsung',
        'models': ['SM-S901B', 'SM-G991B', 'SM-A536B'],
      },
      {
        'make': 'Apple',
        'models': ['iPhone 13', 'iPhone 14', 'iPhone 15'],
      },
      {
        'make': 'Google',
        'models': ['Pixel 6', 'Pixel 7', 'Pixel 8'],
      },
      {
        'make': 'Xiaomi',
        'models': ['2201117TY', '2210132G'],
      },
    ];

    final device = devices[rng.nextInt(devices.length)];
    final modelList = device['models'] as List<String>;

    return _StealthProfile(
      brightness: (rng.nextDouble() * 0.04) - 0.02, // ±0.02
      contrast: 1.0 + (rng.nextDouble() * 0.04) - 0.02, // 0.98-1.02
      saturation: 1.0 + (rng.nextDouble() * 0.06) - 0.03, // 0.97-1.03
      hue: (rng.nextDouble() * 2.0) - 1.0, // ±1.0 degree
      noise: 0.3 + (rng.nextDouble() * 0.5), // 0.3-0.8
      cropOffsetX: rng.nextInt(3), // 0-2
      cropOffsetY: rng.nextInt(3), // 0-2
      extraScale: 2 + rng.nextInt(3), // 2-4
      creationTime: dateStr,
      make: device['make'] as String,
      model: modelList[rng.nextInt(modelList.length)],
    );
  }
}

class ImagePosterService {
  static String get _ffmpegBin => Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
  static String get _ffprobeBin =>
      Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';

  Future<bool> _checkFfmpeg() async {
    try {
      final result = await Process.run(_ffmpegBin, ['-version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkFfprobe() async {
    try {
      final result = await Process.run(_ffprobeBin, ['-version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  final List<Process> _activeProcesses = [];
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
    for (final process in _activeProcesses) {
      try {
        process.kill();
      } catch (_) {}
    }
    _activeProcesses.clear();
  }

  static int get _maxConcurrentTasks => Platform.numberOfProcessors.clamp(2, 8);

  Stream<String> generateImagePosters({
    required List<String> sourceVideoPaths,
    required ImagePosterConfig config,
    required Map<String, Uint8List> slideOverlayBytes,
    void Function(String dir)? onOutputDir,
  }) async* {
    _cancelled = false;
    _activeProcesses.clear();

    // Validate ffmpeg availability - Based on BatchVideoService
    if (!await _checkFfmpeg()) {
      yield '❌ FFmpeg chưa được cài đặt! Vui lòng cài FFmpeg trước.';
      yield '   Windows: https://ffmpeg.org/download.html';
      return;
    }
    if (!await _checkFfprobe()) {
      yield '❌ FFprobe chưa được cài đặt! Vui lòng kiểm tra lại bộ FFmpeg.';
      return;
    }

    if (sourceVideoPaths.isEmpty) {
      yield '❌ Không có video nguồn!';
      return;
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('-', '')
        .replaceAll('T', '_')
        .substring(0, 15);

    String baseOutputDir = config.outputDir ?? await _getDefaultOutputDir();
    final outputDir = p.join(baseOutputDir, 'image_posters_$timestamp');
    await Directory(outputDir).create(recursive: true);
    onOutputDir?.call(outputDir);

    final tempDir = Directory(
      p.join(Directory.systemTemp.path, 'scraki_image_temp_$timestamp'),
    );
    await tempDir.create(recursive: true);

    try {
      yield '📋 Đang kiểm tra video nguồn...';
      final videoDurations = <String, int>{};
      for (final path in sourceVideoPaths) {
        final duration = await _getVideoDuration(path);
        if (duration > 0) {
          videoDurations[path] = duration;
        }
      }

      if (videoDurations.isEmpty) {
        yield '❌ Không có video hợp lệ!';
        return;
      }

      final random = Random();
      final totalSets = config.outputCount;
      final slides = config.slides;

      // Save slide overlay bytes to temp files
      final overlayFilePaths = <String, String>{};
      for (final entry in slideOverlayBytes.entries) {
        final filePath = p.join(tempDir.path, 'overlay_${entry.key}.png');
        await File(filePath).writeAsBytes(entry.value);
        overlayFilePaths[entry.key] = filePath;
      }

      final totalImages = totalSets * slides.length;
      yield '🚀 Bắt đầu tạo $totalSets bộ ảnh ($totalImages ảnh tổng cộng)...';

      final activeTasks = <Future<void>>{};
      int completedCount = 0;

      // Use a StreamController to feed progress back from parallel tasks
      final progressController = StreamController<String>();

      // Internal function to process one image
      Future<void> processImage(
        int setIndex,
        int slideIndex,
        String setDir,
      ) async {
        if (_cancelled) return;

        final slide = slides[slideIndex];
        final videoPath = videoDurations.keys.elementAt(
          random.nextInt(videoDurations.length),
        );
        final duration = videoDurations[videoPath]!;

        final randomTime = _pickFrameTime(
          duration: duration,
          setIndex: setIndex,
          totalSets: totalSets,
          slideIndex: slideIndex,
          totalSlides: slides.length,
          rng: random,
        );

        final stealth = _StealthProfile.random(random);
        final randomSuffix = random.nextInt(9000) + 1000;
        final extension = config.outputFormat.toLowerCase().replaceAll('.', '');

        // Fix: Use padded index first for correct OS sorting
        final outputFileName =
            'IMG_${(slideIndex + 1).toString().padLeft(3, '0')}$randomSuffix.$extension';
        final outputPath = p.join(setDir, outputFileName);
        final overlayPath = overlayFilePaths[slide.id];

        if (overlayPath == null) {
          progressController.add(
            '  ⚠️ [Bộ $setIndex] Không tìm thấy overlay cho ${slide.name}',
          );
          return;
        }

        final success = await _composeImage(
          videoPath: videoPath,
          time: randomTime,
          overlayPath: overlayPath,
          outputPath: outputPath,
          width: config.width,
          height: config.height,
          stealth: stealth,
          format: config.outputFormat,
        );

        completedCount++;
        if (success) {
          progressController.add(
            '  ✅ [Bộ $setIndex] Xong $outputFileName ($completedCount/$totalImages)',
          );
        } else {
          progressController.add('  ❌ [Bộ $setIndex] Lỗi $outputFileName');
        }
      }

      // Start the task pump
      () async {
        final platformPrefix = config.platformSet.prefix;
        for (int i = 1; i <= totalSets; i++) {
          if (_cancelled) break;

          final randomId = 1000000 + random.nextInt(9000000);
          final String folderName;
          if (config.platformSet == PosterPlatformSet.facebook) {
            folderName = '${platformPrefix}_${config.facebookSubtype.name}_${i}_$randomId';
          } else {
            folderName = '${platformPrefix}_${i}_$randomId';
          }
          final setDir = p.join(
            outputDir,
            folderName,
          );
          await Directory(setDir).create(recursive: true);

          for (int j = 0; j < slides.length; j++) {
            if (_cancelled) break;

            while (activeTasks.length >= _maxConcurrentTasks) {
              await Future.any(activeTasks);
            }
            if (_cancelled) break;

            final Future<void> trackedTask = processImage(i, j, setDir);
            activeTasks.add(trackedTask);
            trackedTask.then((_) => activeTasks.remove(trackedTask));
          }
        }
        await Future.wait(activeTasks);
        await progressController.close();
      }();

      // Yield values from the controller
      await for (final msg in progressController.stream) {
        yield msg;
      }

      if (_cancelled) {
        yield '🛑 Đã dừng.';
      } else {
        yield '✅ Hoàn tất! Ảnh đã được lưu tại: $outputDir';
      }
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  Future<String> _getDefaultOutputDir() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    String desktopPath;
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      desktopPath = userProfile != null
          ? p.join(userProfile, 'Desktop')
          : p.join(documentsDir.parent.path, 'Desktop');
    } else {
      desktopPath = p.join(documentsDir.parent.path, 'Desktop');
    }

    if (await Directory(desktopPath).exists()) {
      return desktopPath;
    }
    return documentsDir.path;
  }

  Future<int> _getVideoDuration(String path) async {
    try {
      final result = await Process.run(_ffprobeBin, [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'default=noprint_wrappers=1:nokey=1',
        path,
      ]);
      final output = result.stdout as String;
      // Robust parsing matching BatchVideoService
      return double.tryParse(output.trim())?.round() ?? 0;
    } catch (e) {
      debugPrint('Error probing duration for $path: $e');
      return 0;
    }
  }

  int _pickFrameTime({
    required int duration,
    required int setIndex,
    required int totalSets,
    required int slideIndex,
    required int totalSlides,
    required Random rng,
  }) {
    if (duration <= 1) return 0;

    // Chia timeline thành các vùng lớn dựa trên số lượng slide
    final double slideRegionSize = duration / totalSlides;
    final double startOfSlideRegion = slideIndex * slideRegionSize;

    // Trong mỗi slide region, chia nhỏ tiếp dựa trên số lượng Set để tránh trùng lặp
    final double setSubRegionSize = slideRegionSize / totalSets;
    final double startOfSetSubRegion =
        startOfSlideRegion + (setIndex - 1) * setSubRegionSize;

    // Pick một điểm ngẫu nhiên trong sub-region của Set này
    final int jitterRange = max(1, setSubRegionSize.floor());
    int pickedTime = startOfSetSubRegion.floor() + rng.nextInt(jitterRange);

    return pickedTime.clamp(0, duration - 1);
  }

  Future<bool> _composeImage({
    required String videoPath,
    required int time,
    required String overlayPath,
    required String outputPath,
    required int width,
    required int height,
    required _StealthProfile stealth,
    required String format,
  }) async {
    try {
      final isJpg =
          format.toLowerCase().endsWith('jpg') ||
          format.toLowerCase().endsWith('jpeg');

      // Build complex filter for visual jitter and micro-crop jitter
      final double zoomVal = 1.0 + (stealth.extraScale / width);
      final int scaledW = (width * zoomVal).round();
      final int scaledH = (height * zoomVal).round();

      final filter = [
        '[0:v]scale=$scaledW:$scaledH:force_original_aspect_ratio=increase,',
        'crop=$width:$height:${stealth.cropOffsetX}:${stealth.cropOffsetY},',
        'eq=brightness=${stealth.brightness.toStringAsFixed(4)}:contrast=${stealth.contrast.toStringAsFixed(4)}:saturation=${stealth.saturation.toStringAsFixed(4)},',
        'hue=h=${stealth.hue.toStringAsFixed(2)},',
        'noise=alls=${stealth.noise.toStringAsFixed(2)}:allf=t[bg];',
        '[bg][1:v]overlay=0:0',
      ].join('');

      final List<String> args = [
        '-hide_banner',
        '-y',
        '-hwaccel',
        'auto',
        '-ss',
        time.toString(),
        '-i',
        videoPath,
        '-i',
        overlayPath,
        '-filter_complex',
        filter,
        '-vframes',
        '1',
      ];

      if (isJpg) {
        args.addAll([
          '-q:v', '2',
          '-pix_fmt', 'yuvj420p',
          '-map_metadata', '-1', // Clear global metadata
          '-metadata:s:v:0', 'make=${stealth.make}',
          '-metadata:s:v:0', 'model=${stealth.model}',
          '-metadata:s:v:0', 'creation_time=${stealth.creationTime}',
        ]);
      } else {
        args.addAll([
          '-pix_fmt',
          'rgba',
          '-metadata',
          'Software=',
          '-metadata',
          'Creation Time=${stealth.creationTime}',
          '-metadata',
          'Title=IMG_${stealth.creationTime.replaceAll(':', '').replaceAll(' ', '_')}',
        ]);
      }

      args.addAll([
        '-fflags',
        '+bitexact',
        '-flags:v',
        '+bitexact',
        outputPath,
      ]);

      final process = await Process.start(_ffmpegBin, args);
      _activeProcesses.add(process);

      final stderrList = <String>[];
      process.stderr.listen((data) {
        final out = String.fromCharCodes(data);
        final lines = out.split('\n');
        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            stderrList.add(line);
            if (stderrList.length > 20) stderrList.removeAt(0);
          }
        }
      });

      final exitCode = await process.exitCode;
      _activeProcesses.remove(process);

      if (exitCode != 0) {
        debugPrint('FFmpeg Error composing image:\n${stderrList.join('\n')}');
      }

      return exitCode == 0;
    } catch (e) {
      debugPrint('Error starting FFmpeg for image composition: $e');
      return false;
    }
  }
}
