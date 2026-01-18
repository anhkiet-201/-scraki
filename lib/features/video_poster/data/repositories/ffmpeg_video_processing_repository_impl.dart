import 'dart:io';
import 'dart:math';
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

    // 1. Check for FFmpeg
    final ffmpegPath = await _findFfmpeg();
    if (ffmpegPath == null) {
      throw Exception(
        'FFmpeg not found. Please install FFmpeg (brew install ffmpeg).',
      );
    }

    // 2. Build Inputs
    // ignore: unused_local_variable
    final inputs = StringBuffer();
    for (var i = 0; i < composition.sourceVideoPaths.length; i++) {
      inputs.write('-i "${composition.sourceVideoPaths[i]}" ');
    }

    // 3. Randomization Parameters (Anti-Reup)
    final random = Random();
    // ignore: unused_local_variable
    final speed = 0.9 + random.nextDouble() * 0.2; // 0.9x - 1.1x
    final contrast = 1.0 + random.nextDouble() * 0.2; // 1.0 - 1.2

    final jobTitle = _sanitizeText(composition.posterData.jobTitle);
    final salary = _sanitizeText(composition.posterData.salaryRange);

    // Very basic filter graph:
    // [0:v]scale=720:1280:force_original_aspect_ratio=increase,crop=720:1280,setsar=1[v0];
    // ... concat ... [v]drawtext=...[out]

    // For MVP, just taking the first video and processing it.

    final inputCount = composition.sourceVideoPaths.length;

    if (inputCount == 0) {
      throw Exception('No input videos selected');
    }

    final input = composition.sourceVideoPaths.first;

    // Construct command arguments
    // Note: process_run shell arguments need careful escaping or list format.
    // Using list format with Process.run is safer.

    final args = [
      '-y',
      '-i',
      input,
      '-vf',
      'scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2,eq=contrast=$contrast:saturation=1.2,drawtext=text=\'$jobTitle\':x=(w-text_w)/2:y=100:fontsize=64:fontcolor=white:shadowcolor=black:shadowx=2:shadowy=2,drawtext=text=\'$salary\':x=(w-text_w)/2:y=200:fontsize=48:fontcolor=yellow',
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-t',
      '${composition.targetDuration.inSeconds}',
      outputPath,
    ];

    print('Executing FFmpeg: $ffmpegPath ${args.join(' ')}');

    final result = await Process.run(ffmpegPath, args);

    if (result.exitCode == 0) {
      return outputPath;
    } else {
      throw Exception(
        'FFmpeg failed (Exit ${result.exitCode}): ${result.stderr}',
      );
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
}
