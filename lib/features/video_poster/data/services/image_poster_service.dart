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

  const SlideOverlayData({
    required this.bytes,
    required this.slideId,
  });
}

class ImagePosterService {
  static String get _ffmpegBin => Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
  static String get _ffprobeBin => Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';

  final List<Process> _activeProcesses = [];
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
    for (final process in _activeProcesses) {
      process.kill();
    }
    _activeProcesses.clear();
  }

  Stream<String> generateImagePosters({
    required List<String> sourceVideoPaths,
    required ImagePosterConfig config,
    required Map<String, Uint8List> slideOverlayBytes,
    void Function(String dir)? onOutputDir,
  }) async* {
    _cancelled = false;
    _activeProcesses.clear();

    if (sourceVideoPaths.isEmpty) {
      yield '❌ Không có video nguồn!';
      return;
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('-', '').replaceAll('T', '_').substring(0, 15);
    
    String baseOutputDir = config.outputDir ?? await _getDefaultOutputDir();
    final outputDir = p.join(baseOutputDir, 'image_posters_$timestamp');
    await Directory(outputDir).create(recursive: true);
    onOutputDir?.call(outputDir);

    final tempDir = Directory(p.join(Directory.systemTemp.path, 'scraki_image_temp_$timestamp'));
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

      yield '🚀 Bắt đầu tạo $totalSets bộ ảnh rải rác...';

      for (int i = 1; i <= totalSets; i++) {
        if (_cancelled) break;
        
        final setDir = p.join(outputDir, 'Set_${i}_${DateTime.now().microsecondsSinceEpoch}');
        await Directory(setDir).create(recursive: true);
        
        yield '📂 Đang tạo Bộ $i...';

        for (int j = 0; j < slides.length; j++) {
          if (_cancelled) break;
          
          final slide = slides[j];
          final videoPath = videoDurations.keys.elementAt(random.nextInt(videoDurations.length));
          final duration = videoDurations[videoPath]!;
          final randomTime = random.nextInt(max(1, duration - 1));
          
          final outputFileName = 'Slide_${j + 1}.png';
          final outputPath = p.join(setDir, outputFileName);
          final overlayPath = overlayFilePaths[slide.id];

          if (overlayPath == null) {
            yield '⚠️ Không tìm thấy dữ liệu overlay cho slide ${slide.name}';
            continue;
          }

          final success = await _composeImage(
            videoPath: videoPath,
            time: randomTime,
            overlayPath: overlayPath,
            outputPath: outputPath,
            width: config.width,
            height: config.height,
          );

          if (success) {
            yield '  ✅ [Bộ $i] Đã xong $outputFileName';
          } else {
            yield '  ❌ [Bộ $i] Lỗi khi tạo $outputFileName';
          }
        }
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
      desktopPath = userProfile != null ? p.join(userProfile, 'Desktop') : p.join(documentsDir.parent.path, 'Desktop');
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
        '-v', 'error',
        '-show_entries', 'format=duration',
        '-of', 'default=noprint_wrappers=1:nokey=1',
        path,
      ]);
      final output = result.stdout as String;
      return double.tryParse(output.trim())?.round() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> _composeImage({
    required String videoPath,
    required int time,
    required String overlayPath,
    required String outputPath,
    required int width,
    required int height,
  }) async {
    try {
      final process = await Process.start(_ffmpegBin, [
        '-y',
        '-ss', time.toString(),
        '-i', videoPath,
        '-i', overlayPath,
        '-filter_complex',
        '[0:v]scale=$width:$height:force_original_aspect_ratio=increase,crop=$width:$height[bg];[bg][1:v]overlay=0:0',
        '-vframes', '1',
        outputPath,
      ]);
      _activeProcesses.add(process);
      final exitCode = await process.exitCode;
      _activeProcesses.remove(process);
      return exitCode == 0;
    } catch (e) {
      debugPrint('Error composing image: $e');
      return false;
    }
  }
}
