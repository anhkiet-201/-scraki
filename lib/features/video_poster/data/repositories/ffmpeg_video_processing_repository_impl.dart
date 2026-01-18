import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';
import 'package:scraki/features/video_poster/domain/entities/video_composition.dart';
import 'package:scraki/features/video_poster/domain/repositories/video_processing_repository.dart';

@Injectable(as: VideoProcessingRepository)
class FfmpegVideoProcessingRepositoryImpl implements VideoProcessingRepository {
  @override
  Future<String?> generatePreview(VideoComposition composition) async {
    return null;
  }

  @override
  Future<String> generateVideo(VideoComposition composition) async {
    final outputDir = await getApplicationDocumentsDirectory();
    final outputPath = '${outputDir.path}/output_${composition.id}.mp4';

    final ffmpegPath = await _findFfmpeg();
    if (ffmpegPath == null) {
      throw Exception('FFmpeg not found.');
    }

    if (composition.sourceVideoPaths.isEmpty) {
      throw Exception('No input videos selected');
    }

    final jobTitle = _sanitizeText(composition.posterData.jobTitle);
    final salary = _sanitizeText(composition.posterData.salaryRange);
    final company = _sanitizeText(composition.posterData.companyName);
    final location = _sanitizeText(composition.posterData.location);
    final contact = _sanitizeText(composition.posterData.contactInfo);
    final headline = _sanitizeText(composition.posterData.catchyHeadline ?? "");
    final requirements = composition.posterData.requirements
        .map((r) => "• ${_sanitizeText(r)}")
        .join("\n");
    final benefits = composition.posterData.benefits
        .map((b) => "• ${_sanitizeText(b)}")
        .join("\n");

    const fontPath = '/System/Library/Fonts/Supplemental/Arial.ttf';

    // Calculate total duration to handle 15s minimum
    double totalInputDuration = 0;
    for (final path in composition.sourceVideoPaths) {
      totalInputDuration += await _getVideoDuration(path, ffmpegPath);
    }

    // Apply playback speed factor
    final speed = composition.playbackSpeed;
    double effectiveDuration = totalInputDuration / speed;

    int loopCount = 1;
    if (effectiveDuration < 15.0) {
      loopCount = (15.0 / effectiveDuration).ceil();
    }

    // Filter Building
    final List<String> inputs = [];
    final List<String> videoFilterParts = [];

    for (int i = 0; i < composition.sourceVideoPaths.length; i++) {
      inputs.addAll(['-i', composition.sourceVideoPaths[i]]);
      // Scale each input and normalize FPS/Format for reliable concat
      videoFilterParts.add(
        '[$i:v]scale=720:1280:force_original_aspect_ratio=increase,crop=720:1280,setsar=1,fps=30,format=yuv420p[v$i]',
      );
    }

    // Concatenate all scaled videos with loops if needed
    final int totalConcatNodes =
        composition.sourceVideoPaths.length * loopCount;
    final concatInputs = List.generate(
      loopCount,
      (l) => List.generate(
        composition.sourceVideoPaths.length,
        (i) => '[v$i]',
      ).join(''),
    ).join('');

    videoFilterParts.add(
      '${concatInputs}concat=n=$totalConcatNodes:v=1:a=0[vconcat]',
    );

    // Apply global effects, Anti-Reup randomization, and text
    final compositionContrast = composition.contrast;
    final compositionSaturation = composition.saturation;
    final compositionSpeed = composition.playbackSpeed;
    final noise = composition.noiseLevel * 100; // Scale for ffmpeg
    final hue = composition.hueShift * 180; // Scale to degrees
    final brightness = composition.brightnessDelta;

    videoFilterParts.add(
      '[vconcat]eq=contrast=$compositionContrast:saturation=$compositionSaturation:brightness=$brightness,'
      'hue=h=$hue,'
      'noise=alls=$noise:allf=t,'
      'setpts=1/$compositionSpeed*PTS,'
      'drawtext=fontfile=$fontPath:text=\'$headline\':x=(w*${composition.headlineX}-text_w/2):y=(h*${composition.headlineY}-text_h/2):fontsize=72:fontcolor=white:shadowcolor=black@0.6:shadowx=2:shadowy=2,'
      'drawtext=fontfile=$fontPath:text=\'$jobTitle\':x=(w*${composition.titleX}-text_w/2):y=(h*${composition.titleY}-text_h/2):fontsize=64:fontcolor=white:shadowcolor=black:shadowx=2:shadowy=2,'
      'drawtext=fontfile=$fontPath:text=\'$location\':x=(w*${composition.locationX}-text_w/2):y=(h*${composition.locationY}-text_h/2):fontsize=32:fontcolor=white@0.8,'
      'drawtext=fontfile=$fontPath:text=\'$salary\':x=(w*${composition.salaryX}-text_w/2):y=(h*${composition.salaryY}-text_h/2):fontsize=48:fontcolor=yellow,'
      'drawtext=fontfile=$fontPath:text=\'$company\':x=(w*${composition.companyX}-text_w/2):y=(h*${composition.companyY}-text_h/2):fontsize=32:fontcolor=white@0.7,'
      'drawtext=fontfile=$fontPath:text=\'$requirements\':x=(w*${composition.requirementsX}):y=(h*${composition.requirementsY}):fontsize=28:fontcolor=white:line_spacing=5,'
      'drawtext=fontfile=$fontPath:text=\'$benefits\':x=(w*${composition.benefitsX}):y=(h*${composition.benefitsY}):fontsize=28:fontcolor=white:line_spacing=5,'
      'drawtext=fontfile=$fontPath:text=\'$contact\':x=(w*${composition.contactX}-text_w/2):y=(h*${composition.contactY}-text_h/2):fontsize=36:fontcolor=white:box=1:boxcolor=black@0.4:boxborderw=8[vfinal]',
    );

    final filterComplex = videoFilterParts.join(';');

    final args = [
      '-y',
      ...inputs,
      '-filter_complex',
      filterComplex,
      '-map',
      '[vfinal]',
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-crf',
      '23',
      // Duration clamping (15-30s)
      '-t',
      '30', // Max 30s
      outputPath,
    ];

    final result = await Process.run(ffmpegPath, args);

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
    final outputDir = await getTemporaryDirectory();
    final outputPath =
        '${outputDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ffmpegPath = await _findFfmpeg();
    if (ffmpegPath == null) throw Exception('FFmpeg not found');

    final args = [
      '-y',
      '-ss',
      '00:00:01',
      '-i',
      videoPath,
      '-vframes',
      '1',
      '-q:v',
      '2',
      outputPath,
    ];

    final result = await Process.run(ffmpegPath, args);
    if (result.exitCode == 0) {
      return outputPath;
    } else {
      throw Exception('Thumbnail failed: ${result.stderr}');
    }
  }

  Future<String?> _findFfmpeg() async {
    // Check usual locations or use 'which'
    final whichBin = await which('ffmpeg');
    if (whichBin != null) return whichBin;

    if (await File('/opt/homebrew/bin/ffmpeg').exists())
      return '/opt/homebrew/bin/ffmpeg';
    if (await File('/usr/local/bin/ffmpeg').exists())
      return '/usr/local/bin/ffmpeg';

    return null;
  }

  String _sanitizeText(String text) {
    // Escape single quotes and colons for ffmpeg drawtext
    return text.replaceAll("'", "").replaceAll(":", "\\:");
  }

  Future<double> _getVideoDuration(String path, String ffmpegPath) async {
    final ffprobePath = ffmpegPath.replaceAll('ffmpeg', 'ffprobe');
    final args = [
      '-v',
      'error',
      '-show_entries',
      'format=duration',
      '-of',
      'default=noprint_wrappers=1:nokey=1',
      path,
    ];
    final result = await Process.run(ffprobePath, args);
    if (result.exitCode == 0) {
      return double.tryParse(result.stdout.toString().trim()) ?? 0.0;
    }
    return 0.0;
  }
}
