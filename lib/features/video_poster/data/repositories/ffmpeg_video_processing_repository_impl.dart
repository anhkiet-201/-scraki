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

    const fontPath = '/System/Library/Fonts/Supplemental/Arial Bold.ttf';

    // Helper: Manual Text Wrapping for Headline & Title
    String wrapText(String text, int maxChars) {
      if (text.length <= maxChars) return text;
      final words = text.split(' ');
      final List<String> lines = [];
      String currentLine = "";
      for (final word in words) {
        if ((currentLine + word).length > maxChars) {
          lines.add(currentLine.trim());
          currentLine = word + " ";
        } else {
          currentLine += word + " ";
        }
      }
      if (currentLine.isNotEmpty) lines.add(currentLine.trim());
      return lines.join('\n');
    }

    final jobTitle = _sanitizeTextForFilter(composition.posterData.jobTitle);
    final salary = _sanitizeTextForFilter(composition.posterData.salaryRange);
    final company = _sanitizeTextForFilter(composition.posterData.companyName);
    final location = _sanitizeTextForFilter(composition.posterData.location);
    final contact = _sanitizeTextForFilter(composition.posterData.contactInfo);
    final headline = _sanitizeTextForFilter(
      composition.posterData.catchyHeadline ?? "",
    );

    // Use \\n (escaped \n) for FFmpeg drawtext multiline
    final wrappedHeadline = wrapText(headline, 22).replaceAll('\n', r'\n');
    final wrappedJobTitle = wrapText(jobTitle, 18).replaceAll('\n', r'\n');
    final wrappedCompany = wrapText(company, 25).replaceAll('\n', r'\n');
    final wrappedLocation = wrapText(location, 25).replaceAll('\n', r'\n');
    final wrappedSalary = wrapText(salary, 20).replaceAll('\n', r'\n');
    final wrappedContact = wrapText(contact, 25).replaceAll('\n', r'\n');

    // Prepare Requirements & Benefits with labels and wrapping
    final reqItems = composition.posterData.requirements
        .map(
          (r) =>
              "• ${wrapText(_sanitizeTextForFilter(r).replaceAll('\n', ' '), 35).replaceAll('\n', r'\n')}",
        )
        .join(r"\n");
    final wrappedRequirements = "YÊU CẦU:\\n$reqItems";

    final benItems = composition.posterData.benefits
        .map(
          (b) =>
              "• ${wrapText(_sanitizeTextForFilter(b).replaceAll('\n', ' '), 35).replaceAll('\n', r'\n')}",
        )
        .join(r"\n");
    final wrappedBenefits = "QUYỀN LỢI:\\n$benItems";

    // Calculate total duration to handle 15s minimum
    double totalInputDuration = 0;
    for (final path in composition.sourceVideoPaths) {
      totalInputDuration += await _getVideoDuration(path, ffmpegPath);
    }

    final speed = composition.playbackSpeed;
    double effectiveDuration = totalInputDuration / speed;

    int loopCount = 1;
    if (effectiveDuration < 15.0) {
      loopCount = (15.0 / effectiveDuration).ceil();
    }

    final List<String> inputs = [];
    final List<String> videoFilterParts = [];

    for (int i = 0; i < composition.sourceVideoPaths.length; i++) {
      inputs.addAll(['-i', composition.sourceVideoPaths[i]]);
      videoFilterParts.add(
        '[$i:v]scale=720:1280:force_original_aspect_ratio=increase,crop=720:1280,setsar=1,fps=30,format=yuv420p[v$i]',
      );
    }

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

    final compositionContrast = composition.contrast;
    final compositionSaturation = composition.saturation;
    final compositionSpeed = composition.playbackSpeed;
    final noise = composition.noiseLevel * 100;
    final hue = composition.hueShift * 180;
    final brightness = composition.brightnessDelta;

    videoFilterParts.add(
      '[vconcat]eq=contrast=$compositionContrast:saturation=$compositionSaturation:brightness=$brightness,'
      'hue=h=$hue,'
      'noise=alls=$noise:allf=t,'
      'setpts=1/$compositionSpeed*PTS,'
      'drawtext=fontfile=$fontPath:text=\'$wrappedHeadline\':x=(w-text_w)*${composition.headlineX}:y=(h-text_h)*${composition.headlineY}:fontsize=36:fontcolor=0xFFFF00:shadowcolor=0x000000@0.6:shadowx=2:shadowy=2:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=12:line_spacing=5,'
      'drawtext=fontfile=$fontPath:text=\'$wrappedJobTitle\':x=(w-text_w)*${composition.titleX}:y=(h-text_h)*${composition.titleY}:fontsize=52:fontcolor=0xFFFFFF:shadowcolor=0x000000:shadowx=2:shadowy=2:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=12:line_spacing=5,'
      'drawtext=fontfile=$fontPath:text=\'$wrappedLocation\':x=(w-text_w)*${composition.locationX}:y=(h-text_h)*${composition.locationY}:fontsize=28:fontcolor=0xFFFFFF:shadowcolor=0x000000@0.4:shadowx=1:shadowy=1:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=8,'
      'drawtext=fontfile=$fontPath:text=\'$wrappedSalary\':x=(w-text_w)*${composition.salaryX}:y=(h-text_h)*${composition.salaryY}:fontsize=40:fontcolor=0xFFFF00:shadowcolor=0x000000:shadowx=2:shadowy=2:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=10,'
      'drawtext=fontfile=$fontPath:text=\'$wrappedCompany\':x=(w-text_w)*${composition.companyX}:y=(h-text_h)*${composition.companyY}:fontsize=32:fontcolor=0xFFFFFF:shadowcolor=0x000000@0.3:shadowx=1:shadowy=1:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=8,'
      'drawtext=fontfile=$fontPath:text=\'$wrappedRequirements\':x=(w-text_w)*${composition.requirementsX}:y=(h-text_h)*${composition.requirementsY}:fontsize=28:fontcolor=0xFFFFFF:line_spacing=6:shadowcolor=0x000000@0.5:shadowx=1:shadowy=1:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=10,'
      'drawtext=fontfile=$fontPath:text=\'$wrappedBenefits\':x=(w-text_w)*${composition.benefitsX}:y=(h-text_h)*${composition.benefitsY}:fontsize=28:fontcolor=0x69F0AE:line_spacing=6:shadowcolor=0x000000@0.5:shadowx=1:shadowy=1:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=10,'
      'drawtext=fontfile=$fontPath:text=\'$wrappedContact\':x=(w-text_w)*${composition.contactX}:y=(h-text_h)*${composition.contactY}:fontsize=32:fontcolor=0xFFFFFF:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=12[vfinal]',
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
      '-t',
      '30',
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
    final whichBin = await which('ffmpeg');
    if (whichBin != null) return whichBin;
    if (await File('/opt/homebrew/bin/ffmpeg').exists())
      return '/opt/homebrew/bin/ffmpeg';
    if (await File('/usr/local/bin/ffmpeg').exists())
      return '/usr/local/bin/ffmpeg';
    return null;
  }

  String _sanitizeTextForFilter(String text) {
    if (text.isEmpty) return "";
    String sanitized = text
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), ' ')
        .trim();
    sanitized = sanitized.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E6}-\u{1F1FF}]',
        unicode: true,
      ),
      '',
    );
    return sanitized
        .replaceAll("\\", "\\\\")
        .replaceAll(":", "\\\\:")
        .replaceAll(",", "\\\\,")
        .replaceAll("'", "")
        .replaceAll("%", "%%");
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
