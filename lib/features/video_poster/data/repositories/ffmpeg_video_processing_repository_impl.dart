import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scraki/features/video_poster/domain/entities/video_composition.dart';
import 'package:scraki/features/video_poster/domain/repositories/video_processing_repository.dart';

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

    // Calculate total duration to handle 15s minimum
    double totalInputDuration = 0;
    for (final path in composition.sourceVideoPaths) {
      final probe = await Process.run('ffprobe', [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'default=noprint_wrappers=1:nokey=1',
        path,
      ]);
      final dur = double.tryParse(probe.stdout.toString().trim()) ?? 0;
      totalInputDuration += dur;
    }

    final targetDuration = totalInputDuration < 15.0
        ? 15.0
        : totalInputDuration;
    final loopCount = (targetDuration / totalInputDuration).ceil();

    // Save overlay PNG to temp file
    final tempDir = await getTemporaryDirectory();
    final overlayFile = File('${tempDir.path}/overlay_${composition.id}.png');
    await overlayFile.writeAsBytes(overlayPng);

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

    // Video composition settings
    final compositionContrast = composition.contrast;
    final compositionSaturation = composition.saturation * 2;
    final compositionSpeed = 1.0; // Default speed
    final brightness = composition.brightnessDelta;
    final hue = composition.hueShift * 360;
    final noise = (composition.noiseLevel * 30).toInt();

    // Concatenate videos
    String concatFilter = '';
    for (int i = 0; i < totalVideos; i++) {
      concatFilter += '[$i:v:0]';
    }
    concatFilter += 'concat=n=$totalVideos:v=1:a=0[vconcat];';

    // Apply effects and overlay
    final filterComplex =
        concatFilter +
        '[vconcat]eq=contrast=$compositionContrast:saturation=$compositionSaturation:brightness=$brightness,' +
        'hue=h=$hue,' +
        'noise=alls=$noise:allf=t,' +
        'setpts=1/$compositionSpeed*PTS[vprocessed];' +
        '[vprocessed][$overlayInputIndex:v]overlay=0:0[vfinal]';

    final args = [
      '-y',
      ...inputs,
      '-filter_complex',
      filterComplex,
      '-map',
      '[vfinal]',
      '-t',
      targetDuration.toString(),
      '-c:v',
      'libx264',
      '-preset',
      'medium',
      '-crf',
      '23',
      outputPath,
    ];

    final result = await Process.run(ffmpegPath, args);

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
