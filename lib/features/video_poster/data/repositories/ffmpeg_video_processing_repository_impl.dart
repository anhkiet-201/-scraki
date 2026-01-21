import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
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

    // 1. Probe all inputs for Audio and Duration
    List<double> inputDurations = [];
    List<bool> inputHasAudio = [];
    double totalInputDuration = 0;

    // Attempt to find ffprobe
    final ffmpegDir = File(ffmpegPath).parent.path;
    final ffprobeExecutable = Platform.isWindows
        ? p.join(ffmpegDir, 'ffprobe.exe')
        : p.join(ffmpegDir, 'ffprobe');

    final ffprobeExists = await File(ffprobeExecutable).exists();
    final ffprobePath = ffprobeExists ? ffprobeExecutable : 'ffprobe';

    for (final path in composition.sourceVideoPaths) {
      double dur = 5.0; // default
      bool hasIdxAudio = false;
      try {
        // Probe duration
        final durResult = await Process.run(ffprobePath, [
          '-v',
          'error',
          '-show_entries',
          'format=duration',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          path,
        ]).timeout(const Duration(seconds: 2));
        dur = double.tryParse(durResult.stdout.toString().trim()) ?? 5.0;

        // Probe audio stream
        final audResult = await Process.run(ffprobePath, [
          '-v',
          'error',
          '-select_streams',
          'a',
          '-show_entries',
          'stream=codec_name',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          path,
        ]).timeout(const Duration(seconds: 2));
        hasIdxAudio = audResult.stdout.toString().trim().isNotEmpty;
      } catch (e) {
        debugPrint('Probe failed for $path: $e');
      }
      inputDurations.add(dur);
      inputHasAudio.add(hasIdxAudio);
      totalInputDuration += dur;
    }

    // Determine target duration and loop count
    final double finalDuration;
    if (composition.antiReupConfig.targetDuration != null) {
      finalDuration = composition.antiReupConfig.targetDuration!;
    } else {
      finalDuration = totalInputDuration < 15.0 ? 15.0 : totalInputDuration;
    }

    // Safety check just in case totalInputDuration is 0
    if (totalInputDuration <= 0) totalInputDuration = 15.0;

    final loopCount = (finalDuration / totalInputDuration).ceil();

    // Setup Temp Overlay ... (omitted, assuming existing code is fine, verified in diff)
    final tempDir = await getTemporaryDirectory();
    final overlayFile = File(
      p.join(tempDir.path, 'overlay_${composition.id}.png'),
    );
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

    // Build FFmpeg Inputs
    final List<String> inputs = [];

    // Source videos are repeated by loopCount
    for (int i = 0; i < loopCount; i++) {
      for (final videoPath in composition.sourceVideoPaths) {
        inputs.add('-i');
        inputs.add(videoPath);
      }
    }

    inputs.add('-i');
    inputs.add(overlayFile.path); // Overlay is input N (where N = totalVideos)

    final int totalVideos = composition.sourceVideoPaths.length * loopCount;
    final int overlayInputIndex = totalVideos;

    // Check if we need audio handling
    // If ANY input has audio, we should output audio.
    // If an input lacks audio, we must fill it with silence.
    final bool globalHasAudio = inputHasAudio.contains(true);

    // Calculate how many silent segments we need
    int silenceNeededCount = 0;
    if (globalHasAudio) {
      for (int i = 0; i < loopCount; i++) {
        for (bool hasA in inputHasAudio) {
          if (!hasA) silenceNeededCount++;
        }
      }
    }

    // If we need silence, add anullsrc as an extra input
    int silenceInputIndex = -1;
    if (silenceNeededCount > 0) {
      inputs.add('-f');
      inputs.add('lavfi');
      inputs.add('-i');
      inputs.add('anullsrc=cl=stereo:r=44100');
      silenceInputIndex = totalVideos + 1; // After overlay
    }

    // --- Filter Complex Construction ---
    String filterComplex = '';

    // 1. Scale all video inputs
    for (int i = 0; i < totalVideos; i++) {
      filterComplex +=
          '[$i:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920[v$i];';
    }

    // 2. Prepare Audio (Split silence if needed)
    if (silenceNeededCount > 0 && silenceInputIndex != -1) {
      // Split the single anullsrc input into N streams: [s0][s1]...
      String splits = '';
      for (int s = 0; s < silenceNeededCount; s++) {
        splits += '[sil_raw$s]';
      }
      filterComplex +=
          '[$silenceInputIndex:a]asplit=$silenceNeededCount$splits;';
    }

    // 3. Concat Preparation
    String concatFilter = '';
    int currentSilenceIndex = 0;

    // Flatten the loop into a linear sequence for filter mapping
    for (int i = 0; i < loopCount; i++) {
      for (int j = 0; j < composition.sourceVideoPaths.length; j++) {
        int streamIndex = (i * composition.sourceVideoPaths.length) + j;

        // Video always exists
        concatFilter += '[v$streamIndex]';

        if (globalHasAudio) {
          if (inputHasAudio[j]) {
            // Use original audio
            concatFilter += '[$streamIndex:a]';
          } else {
            // Use generated silence
            // Trim silence to match video duration
            double dur = inputDurations[j];
            // [sil_rawX] -> atrim -> [a_segX]
            filterComplex +=
                '[sil_raw$currentSilenceIndex]atrim=duration=$dur,asetpts=PTS-STARTPTS[a_seg$streamIndex];';
            concatFilter += '[a_seg$streamIndex]';
            currentSilenceIndex++;
          }
        }
      }
    }

    // 4. Concat Command
    final audioOut = globalHasAudio ? 'a=1' : 'a=0';
    final audioLabel = globalHasAudio ? '[aconcat]' : '';
    concatFilter += 'concat=n=$totalVideos:v=1:$audioOut[vconcat]$audioLabel;';

    filterComplex += concatFilter;

    // ... Rest of the filter chain (Service, Overlay, Trim) ...

    // Video composition settings
    final compositionContrast = composition.contrast;
    final compositionSaturation = composition.saturation;

    // Reuse Service Code (injected) - Ensure we define antiReupService
    final antiReupService = GetIt.I<AntiReupService>();
    final (antiReupVideoFilters, antiReupAudioFilters) = antiReupService
        .generateFilters(composition.antiReupConfig);

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

    // 4. Audio Processing
    // WARNING: 'hasAudio' variable from original code needs to be replaced by 'globalHasAudio'
    bool hasAudio = globalHasAudio;

    if (hasAudio && antiReupAudioFilters.isNotEmpty) {
      filterComplex += ';[aconcat]$antiReupAudioFilters[afinal_tmp]';
    } else if (hasAudio) {
      filterComplex += ';[aconcat]anull[afinal_tmp]';
    }

    // 5. Trim Logic (preserved from previous fix)
    String finalVideoMap = '[vfinal]';
    String finalAudioMap = hasAudio ? '[afinal_tmp]' : '';

    if (composition.antiReupConfig.targetDuration != null) {
      final d = composition.antiReupConfig.targetDuration!;
      filterComplex +=
          ';[vfinal]trim=duration=$d,setpts=PTS-STARTPTS[vtrimmed];';
      finalVideoMap = '[vtrimmed]';

      if (hasAudio) {
        filterComplex +=
            '[afinal_tmp]atrim=duration=$d,asetpts=PTS-STARTPTS[atrimmed];';
        finalAudioMap = '[atrimmed]';
      }
    } else {
      if (hasAudio) {
        finalAudioMap = '[afinal_tmp]';
      }
    }

    debugPrint(
      'Exporting with finalDuration: $finalDuration (Target: ${composition.antiReupConfig.targetDuration})',
    );

    final args = [
      '-y',
      ...inputs,
      '-filter_complex',
      filterComplex,
      '-map',
      finalVideoMap,
      if (hasAudio) ...['-map', finalAudioMap],
      '-t',
      finalDuration.toString(),
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
    final thumbnailPath = p.join(
      tempDir.path,
      'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

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
    // 1. Try bundled FFmpeg first (Windows/macOS)
    final bundledPath = await _getBundledFfmpegPath();
    if (bundledPath != null && await File(bundledPath).exists()) {
      debugPrint('Using bundled FFmpeg: $bundledPath');
      return bundledPath;
    }

    // 2. Try system PATH (Unix-like)
    if (Platform.isMacOS || Platform.isLinux) {
      try {
        final result = await Process.run('which', ['ffmpeg']);
        if (result.exitCode == 0) {
          final path = result.stdout.toString().trim();
          debugPrint('Using system FFmpeg: $path');
          return path;
        }
      } catch (_) {}
    }

    // 3. Try Windows common locations
    if (Platform.isWindows) {
      final commonPaths = [
        r'C:\ffmpeg\bin\ffmpeg.exe',
        r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
      ];

      for (final path in commonPaths) {
        if (await File(path).exists()) {
          debugPrint('Using system FFmpeg: $path');
          return path;
        }
      }
    }

    return null;
  }

  Future<String?> _getBundledFfmpegPath() async {
    if (Platform.isWindows) {
      // Windows: FFmpeg is bundled alongside the executable
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent.path;
      return p.join(exeDir, 'ffmpeg.exe');
    } else if (Platform.isMacOS) {
      // macOS: FFmpeg is in the app bundle Resources folder
      final exePath = Platform.resolvedExecutable;
      final resourcesDir = File(exePath).parent.parent.path;
      return p.join(resourcesDir, 'Resources', 'ffmpeg');
    }
    return null;
  }
}
