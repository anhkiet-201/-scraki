import 'dart:io';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/execution_result.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/ffmpeg_options.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/toolkit/video_toolkit.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart';

abstract class BaseFfmpegToolkit implements VideoToolkit {
  final VideoHardwareCapabilityResolver hardwareResolver;

  BaseFfmpegToolkit(this.hardwareResolver);

  GpuInfo get gpuInfo => hardwareResolver.gpuInfo!;

  @override
  void buildConcatInput(FfmpegInputArgs inputs, List<String> paths, String outputDir, int index) {
    final concatFile = File('$outputDir/concat_$index.txt');
    concatFile.writeAsStringSync(paths.map((p) => "file '$p'").join('\n'));
    inputs.addConcatInput(concatFile.absolute.path);
  }

  @override
  Future<ExecutionResult> runToolkit(
    List<String> args,
    VideoBatchExecutionContext context, {
    void Function(String)? onLog,
    void Function(double)? onProgress,
    int? targetDuration,
  }) async {
    final process = await Process.start(hardwareResolver.ffmpegBin, args);
    context.addProcess(process);
    
    final regex = RegExp(r'time=(\d{2}):(\d{2}):(\d{2}\.\d{2})');
    process.stderr.listen((data) {
      final out = String.fromCharCodes(data);
      if (onLog != null) onLog(out);
      
      if (onProgress != null && targetDuration != null && !context.cancelled) {
        final match = regex.firstMatch(out);
        if (match != null) {
          final currentSeconds = int.parse(match.group(1)!) * 3600 + 
                                int.parse(match.group(2)!) * 60 + 
                                double.parse(match.group(3)!);
          onProgress((currentSeconds / targetDuration).clamp(0.0, 1.0));
        }
      }
    });

    final exitCode = await process.exitCode;
    context.removeProcess(process);
    
    if (exitCode == 0) {
      return ExecutionResult.success(args.last);
    } else {
      return ExecutionResult.failure('FFmpeg failed with exit code $exitCode');
    }
  }
}
