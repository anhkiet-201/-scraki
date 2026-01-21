import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scraki/features/video_poster/domain/entities/video_composition.dart';
import 'package:scraki/features/video_poster/domain/repositories/video_processing_repository.dart';
import 'package:scraki/features/video_poster/domain/services/anti_reup_service.dart';

@Injectable(as: VideoProcessingRepository)
class FfmpegVideoProcessingRepositoryImpl implements VideoProcessingRepository {
  @override
  Future<String?> generatePreview(VideoComposition composition) async {
    return null;
  }

  @override
  Future<String> generateVideo(
    VideoComposition composition,
    Uint8List overlayPng,
  ) async {
    final outputDir = await getApplicationDocumentsDirectory();
    final outputPath = '${outputDir.path}/output_${composition.id}.mp4';

    final ffmpegPath = await _findFfmpeg();
    if (ffmpegPath == null) {
      throw Exception('FFmpeg not found.');
    }

    if (composition.sourceVideoPaths.isEmpty) {
      throw Exception('No input videos selected');
    }

    // Check for audio streams
    bool hasAudio = false;

    // Attempt to find ffprobe: assume it's in the same directory as ffmpeg
    final ffmpegDir = File(ffmpegPath).parent.path;
    final ffprobePath = '$ffmpegDir/ffprobe';

    // Check first video for audio (simplification)
    if (composition.sourceVideoPaths.isNotEmpty) {
      try {
        // Fallback to just 'ffprobe' if constructed path doesn't exist (though usually it does)
        final executable = await File(ffprobePath).exists()
            ? ffprobePath
            : 'ffprobe';

        final audioProbe = await Process.run(executable, [
          '-v',
          'error',
          '-select_streams',
          'a',
          '-show_entries',
          'stream=codec_name',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          composition.sourceVideoPaths.first,
        ]).timeout(const Duration(seconds: 5));

        hasAudio = audioProbe.stdout.toString().trim().isNotEmpty;
      } catch (e) {
        debugPrint('Warning: Failed to probe audio: $e. Assuming no audio.');
        hasAudio = false;
      }
    }

    // Recalculate duration to be safe (previous logic relied on ffprobe too)
    // We should safely calculate duration as well.

    // Calculate total duration to handle 15s minimum
    double totalInputDuration = 0;
    try {
      final executable = await File(ffprobePath).exists()
          ? ffprobePath
          : 'ffprobe';
      for (final path in composition.sourceVideoPaths) {
        final probe = await Process.run(executable, [
          '-v',
          'error',
          '-show_entries',
          'format=duration',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          path,
        ]).timeout(const Duration(seconds: 5));

        final dur = double.tryParse(probe.stdout.toString().trim()) ?? 0;
        totalInputDuration += dur;
      }
    } catch (e) {
      debugPrint(
        'Warning: Failed to probe duration: $e. Using fallback duration.',
      );
      // If probe fails, we can't easily guess duration.
      // Default to 15s if everything fails, or user provided targetDuration?
      // Let's assume 5s per clip as fallback
      totalInputDuration = composition.sourceVideoPaths.length * 5.0;
    }

    final targetDuration = totalInputDuration < 15.0
        ? 15.0
        : totalInputDuration;
    final loopCount = (targetDuration / totalInputDuration).ceil();

    // Save overlay PNG to temp file
    final tempDir = await getTemporaryDirectory();

    final overlayFile = File('${tempDir.path}/overlay_${composition.id}.png');

    try {
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }

      if (overlayFile.existsSync()) {
        overlayFile.deleteSync();
      }
      overlayFile.writeAsBytesSync(overlayPng, flush: true);
    } catch (e) {
      debugPrint('CRITICAL ERROR: Failed to write overlay file: $e');
      throw Exception('Failed to write overlay: $e');
    }

    // Build FFmpeg arguments
    final List<String> inputs = [];

    // Add all source videos (looped if needed)
    for (int i = 0; i < loopCount; i++) {
      for (final videoPath in composition.sourceVideoPaths) {
        inputs.add('-i');
        inputs.add(videoPath);
      }
    }

    // Add overlay PNG as input
    inputs.add('-i');
    inputs.add(overlayFile.path);

    // Build filter complex
    final int totalVideos = composition.sourceVideoPaths.length * loopCount;
    final int overlayInputIndex = totalVideos;

    // Standardize all input videos to 1080x1920 (1080p Vertical)
    String scalingFilters = '';
    for (int i = 0; i < totalVideos; i++) {
      scalingFilters +=
          '[$i:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920[v$i];';
    }

    // Video composition settings
    final compositionContrast = composition.contrast;
    final compositionSaturation = composition.saturation * 2;

    // Service for Anti-Reup filters
    // Ideally injected, but instantiated here for quick integration without running build_runner yet
    final antiReupService = GetIt.I<AntiReupService>();
    final (antiReupVideoFilters, antiReupAudioFilters) = antiReupService
        .generateFilters(composition.antiReupConfig);

    // Concatenate scaled videos with AUDIO (if present)
    String concatFilter = '';
    for (int i = 0; i < totalVideos; i++) {
      // Only map audio if present
      if (hasAudio) {
        concatFilter += '[v$i][$i:a]';
      } else {
        concatFilter += '[v$i]';
      }
    }
    // Set a=1 only if we have audio
    final audioOut = hasAudio ? 'a=1' : 'a=0';
    final audioLabel = hasAudio ? '[aconcat]' : '';
    concatFilter += 'concat=n=$totalVideos:v=1:$audioOut[vconcat]$audioLabel;';

    // Apply effects and overlay
    // 1. Base Style (Eq, Hue, Scale)
    // 2. Anti-Reup Filters (Speed, Noise) handled by service string

    // Construct Video Filter Chain
    // [vconcat] -> Base Style -> [vstyled]
    // [vstyled] -> Anti Reup -> [vprocessed]
    // [vprocessed] -> Overlay -> [vfinal]

    // Simplify: Just use one filter complex string
    // If Anti-Reup filters are empty, we just skip that stage

    // [vconcat] -> Eq/Sat -> [vstyled]
    // [vstyled] -> AntiReup (if any) -> [vprocessed]
    // [vprocessed] -> Overlay -> [vfinal]

    String filterComplex = '$scalingFilters$concatFilter';

    // 1. Base Style
    filterComplex +=
        '[vconcat]eq=contrast=$compositionContrast:saturation=$compositionSaturation[vstyled];';

    // 2. Anti-Reup
    String nextVideoLabel = '[vstyled]';
    if (antiReupVideoFilters.isNotEmpty) {
      filterComplex += '$nextVideoLabel$antiReupVideoFilters[vprocessed];';
      nextVideoLabel = '[vprocessed]';
    }

    // 3. Overlay
    filterComplex += '$nextVideoLabel[$overlayInputIndex:v]overlay=0:0[vfinal]';

    // 4. Audio
    if (hasAudio && antiReupAudioFilters.isNotEmpty) {
      filterComplex += ';[aconcat]$antiReupAudioFilters[afinal]';
    }

    final args = [
      '-y',
      ...inputs,
      '-filter_complex',
      filterComplex,
      '-map',
      '[vfinal]',
      if (hasAudio) ...[
        if (antiReupAudioFilters.isNotEmpty) ...[
          '-map',
          '[afinal]',
        ] else ...[
          '-map',
          '[aconcat]',
        ],
      ],
      '-t',
      targetDuration.toString(),
      '-c:v',
      'libx264',
      '-preset',
      'medium',
      '-crf',
      '23',
      if (hasAudio) ...[
        '-c:a',
        'aac', // Ensure audio codec is set
        '-b:a',
        '192k',
      ],
      outputPath,
    ];

    final result = await Process.run(ffmpegPath, args);

    if (result.exitCode != 0) {
      debugPrint('FFmpeg Error Output: ${result.stderr}');
    }

    // Clean up temp overlay file
    try {
      await overlayFile.delete();
    } catch (_) {}

    if (result.exitCode == 0) {
      return outputPath;
    } else {
      throw Exception(
        'FFmpeg failed (Exit ${result.exitCode}): ${result.stderr}',
      );
    }
  }

  @override
  Future<String> extractThumbnail(String videoPath) async {
    final ffmpegPath = await _findFfmpeg();
    if (ffmpegPath == null) {
      throw Exception('FFmpeg not found');
    }

    final tempDir = await getTemporaryDirectory();
    final thumbnailPath =
        '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await Process.run(ffmpegPath, [
      '-i',
      videoPath,
      '-ss',
      '00:00:01',
      '-vframes',
      '1',
      '-q:v',
      '2',
      thumbnailPath,
    ]);

    return thumbnailPath;
  }

  @override
  Future<Duration> getVideoDuration(String videoPath) async {
    final ffmpegPath = await _findFfmpeg();
    if (ffmpegPath == null) throw Exception('FFmpeg not found');

    final probe = await Process.run('ffprobe', [
      '-v',
      'error',
      '-show_entries',
      'format=duration',
      '-of',
      'default=noprint_wrappers=1:nokey=1',
      videoPath,
    ]);

    final seconds = double.tryParse(probe.stdout.toString().trim()) ?? 0;
    return Duration(milliseconds: (seconds * 1000).toInt());
  }

  Future<String?> _findFfmpeg() async {
    try {
      final result = await Process.run('which', ['ffmpeg']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }
}
