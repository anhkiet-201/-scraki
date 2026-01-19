import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
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

    final jobTitle = _sanitizeText(composition.posterData.jobTitle);
    final salary = _sanitizeText(composition.posterData.salaryRange);
    final company = _sanitizeText(composition.posterData.companyName);
    final location = _sanitizeText(composition.posterData.location);
    final contact = _sanitizeText(composition.posterData.contactInfo);
    final headline = _sanitizeText(composition.posterData.catchyHeadline ?? "");

    // Helper: Manual Text Wrapping for Headline & Title
    String _wrapText(String text, int maxChars) {
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

    final wrappedHeadline = _wrapText(headline, 22);
    final wrappedJobTitle = _wrapText(jobTitle, 18);
    final wrappedCompany = _wrapText(company, 25);
    final wrappedLocation = _wrapText(location, 25);
    final wrappedSalary = _wrapText(salary, 20);
    final wrappedContact = _wrapText(contact, 25);

    // Prepare Requirements & Benefits with manual wrapping for each item
    // Wrap each item to prevent overflow, then flatten to lines
    final reqLines = <String>['YÊU CẦU:'];
    for (final r in composition.posterData.requirements) {
      final cleaned = _sanitizeText(r).replaceAll('\n', ' ');
      final wrapped = _wrapText(cleaned, 40); // Max 40 chars per line
      // Split wrapped text into lines and add bullet to first line only
      final lines = wrapped.split('\n');
      for (int i = 0; i < lines.length; i++) {
        reqLines.add(
          i == 0 ? '• ${lines[i]}' : '  ${lines[i]}',
        ); // Indent continuation lines
      }
    }

    final benLines = <String>['QUYỀN LỢI:'];
    for (final b in composition.posterData.benefits) {
      final cleaned = _sanitizeText(b).replaceAll('\n', ' ');
      final wrapped = _wrapText(cleaned, 40);
      final lines = wrapped.split('\n');
      for (int i = 0; i < lines.length; i++) {
        benLines.add(i == 0 ? '• ${lines[i]}' : '  ${lines[i]}');
      }
    }

    // Create Temporary Files for Text (Robust approach for multiline/Vietnamese)
    final tempDir = await getTemporaryDirectory();
    final hFile = File('${tempDir.path}/h_${composition.id}.txt');
    final tFile = File('${tempDir.path}/t_${composition.id}.txt');
    final lFile = File('${tempDir.path}/l_${composition.id}.txt');
    final sFile = File('${tempDir.path}/s_${composition.id}.txt');
    final cFile = File('${tempDir.path}/c_${composition.id}.txt');
    // Note: Requirements and Benefits will be rendered line-by-line, no temp files needed
    final ctFile = File('${tempDir.path}/ct_${composition.id}.txt');

    await hFile.writeAsString(wrappedHeadline.replaceAll('\n', ' '));
    await tFile.writeAsString(wrappedJobTitle.replaceAll('\n', ' '));
    await lFile.writeAsString(wrappedLocation.replaceAll('\n', ' '));
    await sFile.writeAsString(wrappedSalary.replaceAll('\n', ' '));
    await cFile.writeAsString(wrappedCompany.replaceAll('\n', ' '));
    await ctFile.writeAsString(wrappedContact.replaceAll('\n', ' '));

    // Render Requirements and Benefits as PNG images using Canvas
    // Match UI preview sizing: maxWidth 80% = 576px for 720px video
    final reqImageBytes = await _renderMultilineTextToImage(
      lines: reqLines,
      width: 576, // 720 * 0.8 = 576
      fontSize: 22, // Adjusted from 28 for better UI match (~1.57x scaling)
      textColor: const ui.Color(0xFFFFFFFF), // White
      backgroundColor: const ui.Color(0x72000000), // Black45
      borderColor: const ui.Color(0xCC6366F1), // Indigo with 80% alpha
    );
    final reqImageFile = File('${tempDir.path}/req_${composition.id}.png');
    await reqImageFile.writeAsBytes(reqImageBytes);

    final benImageBytes = await _renderMultilineTextToImage(
      lines: benLines,
      width: 576,
      fontSize: 22, // Match requirements fontSize
      textColor: const ui.Color(0xFF69F0AE), // GreenAccent
      backgroundColor: const ui.Color(0x72000000),
      borderColor: const ui.Color(0xCC6366F1),
    );
    final benImageFile = File('${tempDir.path}/ben_${composition.id}.png');
    await benImageFile.writeAsBytes(benImageBytes);

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

    // Build main filter chain with single-line text overlays
    final List<String> drawtextFilters = [
      'drawtext=fontfile=$fontPath:textfile=\'${hFile.path}\':x=(w-text_w)*${composition.headlineX}:y=(h-text_h)*${composition.headlineY}:fontsize=36:fontcolor=0xFFFF00:shadowcolor=0x000000@0.6:shadowx=2:shadowy=2:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=12',
      'drawtext=fontfile=$fontPath:textfile=\'${tFile.path}\':x=(w-text_w)*${composition.titleX}:y=(h-text_h)*${composition.titleY}:fontsize=52:fontcolor=0xFFFFFF:shadowcolor=0x000000:shadowx=2:shadowy=2:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=12',
      'drawtext=fontfile=$fontPath:textfile=\'${lFile.path}\':x=(w-text_w)*${composition.locationX}:y=(h-text_h)*${composition.locationY}:fontsize=28:fontcolor=0xFFFFFF:shadowcolor=0x000000@0.4:shadowx=1:shadowy=1:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=8',
      'drawtext=fontfile=$fontPath:textfile=\'${sFile.path}\':x=(w-text_w)*${composition.salaryX}:y=(h-text_h)*${composition.salaryY}:fontsize=40:fontcolor=0xFFFF00:shadowcolor=0x000000:shadowx=2:shadowy=2:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=10',
      'drawtext=fontfile=$fontPath:textfile=\'${cFile.path}\':x=(w-text_w)*${composition.companyX}:y=(h-text_h)*${composition.companyY}:fontsize=32:fontcolor=0xFFFFFF:shadowcolor=0x000000@0.3:shadowx=1:shadowy=1:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=8',
    ];

    // Add contact info
    drawtextFilters.add(
      'drawtext=fontfile=$fontPath:textfile=\'${ctFile.path}\':x=(w-text_w)*${composition.contactX}:y=(h-text_h)*${composition.contactY}:fontsize=32:fontcolor=0xFFFFFF:borderw=2:bordercolor=0x6366F1@0.8:box=1:boxcolor=0x000000@0.45:boxborderw=12',
    );

    // Build complete filter chain with text drawtext and image overlays
    videoFilterParts.add(
      '[vconcat]eq=contrast=$compositionContrast:saturation=$compositionSaturation:brightness=$brightness,'
      'hue=h=$hue,'
      'noise=alls=$noise:allf=t,'
      'setpts=1/$compositionSpeed*PTS,'
      '${drawtextFilters.join(",")}[vtxt]',
    );

    // Add Requirements PNG overlay - centered horizontally
    // X position: (720 - 576) / 2 = 72 to center the box
    final reqY = (composition.requirementsY * 1280).toInt();
    inputs.add('-i');
    inputs.add(reqImageFile.path);
    final reqInputIndex = composition.sourceVideoPaths.length;
    videoFilterParts.add('[vtxt][$reqInputIndex:v]overlay=72:$reqY[vreq]');

    // Add Benefits PNG overlay - centered horizontally
    final benY = (composition.benefitsY * 1280).toInt();
    inputs.add('-i');
    inputs.add(benImageFile.path);
    final benInputIndex = composition.sourceVideoPaths.length + 1;
    videoFilterParts.add('[vreq][$benInputIndex:v]overlay=72:$benY[vfinal]');

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

    // Clean up all temp files (text files and PNG images)
    try {
      await hFile.delete();
      await tFile.delete();
      await lFile.delete();
      await sFile.delete();
      await cFile.delete();
      await ctFile.delete();
      await reqImageFile.delete();
      await benImageFile.delete();
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

    if (await File('/opt/homebrew/bin/ffmpeg').exists()) {
      return '/opt/homebrew/bin/ffmpeg';
    }
    if (await File('/usr/local/bin/ffmpeg').exists()) {
      return '/usr/local/bin/ffmpeg';
    }

    return null;
  }

  String _sanitizeText(String text) {
    if (text.isEmpty) return "";

    // 1. Strip all non-printable/control characters (EXCEPT \x0A which is \n for textfile support)
    String sanitized = text
        .replaceAll(RegExp(r'[\x00-\x09\x0B-\x1F\x7F-\x9F]'), ' ')
        .trim();

    // 2. Aggressive emoji stripping (Arial Bold on macOS doesn't support them well in FFmpeg)
    sanitized = sanitized.replaceAll(
      RegExp(
        r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E6}-\u{1F1FF}]',
        unicode: true,
      ),
      '',
    );

    // 3. Simple cleanup for textfile approach
    sanitized = sanitized.replaceAll("'", "");
    sanitized = sanitized.replaceAll("\\", "\\\\");
    sanitized = sanitized.replaceAll("%", "%%");

    return sanitized;
  }

  /// Renders multiline text to a PNG image using Flutter's Canvas API.
  ///
  /// This method creates a transparent PNG with styled text, including:
  /// - Rounded rectangle background box with configurable color and border
  /// - Multiple lines of text with proper spacing and alignment
  /// - Text shadows for better readability
  ///
  /// Used to render Requirements and Benefits sections as PNG images,
  /// which are then composited onto the video via FFmpeg overlay filter.
  /// This approach completely avoids FFmpeg font rendering issues.
  ///
  /// Parameters:
  /// - [lines]: Array of text lines to render (including header)
  /// - [width]: Box width in pixels (typically 576px for 720px video)
  /// - [fontSize]: Font size in pixels (typically 22 for UI match)
  /// - [textColor]: Color for the text
  /// - [backgroundColor]: Background box fill color
  /// - [borderColor]: Border stroke color
  ///
  /// Returns: PNG image data as [Uint8List]
  Future<Uint8List> _renderMultilineTextToImage({
    required List<String> lines,
    required double width,
    required double fontSize,
    required ui.Color textColor,
    required ui.Color backgroundColor,
    required ui.Color borderColor,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Calculate total height based on number of lines
    // UI: vertical padding 6px * 2 (scale) = 12px top + 12px bottom = 24px
    const lineHeight = 1.2; // Tighter than 1.4 to match UI
    const verticalPadding = 24.0; // 12px top + 12px bottom
    final totalHeight = lines.length * fontSize * lineHeight + verticalPadding;

    // Draw rounded rectangle background box
    // UI: borderRadius 6px * 2 scale = 12px
    const borderRadius = 12.0;
    final rrect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, width, totalHeight),
      const ui.Radius.circular(borderRadius),
    );

    final boxPaint = ui.Paint()
      ..color = backgroundColor
      ..style = ui.PaintingStyle.fill;

    final borderPaint = ui.Paint()
      ..color = borderColor
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3; // UI border 1.5 * 2 scale = 3

    canvas.drawRRect(rrect, boxPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Draw each line of text
    // UI: horizontal padding 12px * 2 scale = 24px
    const horizontalPadding = 24.0;
    double yPosition = 12.0; // Top padding
    for (final line in lines) {
      final textStyle = ui.TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: ui.FontWeight.bold,
        shadows: [
          ui.Shadow(
            color: const ui.Color(0x80000000),
            offset: const ui.Offset(2, 2),
            blurRadius: 3,
          ),
        ],
      );

      final paragraphStyle = ui.ParagraphStyle(
        textAlign: ui.TextAlign.left,
        fontSize: fontSize,
        fontWeight: ui.FontWeight.bold,
      );

      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(line);

      final paragraph = paragraphBuilder.build()
        ..layout(
          ui.ParagraphConstraints(width: width - (horizontalPadding * 2)),
        ); // Account for left+right padding

      canvas.drawParagraph(paragraph, ui.Offset(horizontalPadding, yPosition));
      yPosition += fontSize * lineHeight;
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), totalHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
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
