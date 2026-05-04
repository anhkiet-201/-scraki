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
  String rotate(double angle, {int? ow, int? oh}) {
    String res = 'rotate=$angle*PI/180:c=black@0';
    if (ow != null) res += ':ow=$ow';
    if (oh != null) res += ':oh=$oh';
    return res;
  }

  @override
  String fade({required String type, required double start, required double duration}) {
    return 'fade=t=$type:st=$start:d=$duration:alpha=1';
  }

  @override
  String drawbox({required String c, required int t}) {
    return 'drawbox=c=$c:t=$t';
  }

  @override
  String colorToHex(dynamic color) {
    if (color is String) return color;
    
    // Giả định color là một đối tượng Color từ Flutter (0xXXRRGGBB)
    // FFmpeg drawbox/color dùng định dạng 0xRRGGBB hoặc tên màu
    try {
      // Gọi toARGB32() qua dynamic và ép kiểu kết quả về int
      final int argb = (color as dynamic).toARGB32() as int;
      final String hex = argb.toRadixString(16).padLeft(8, '0');
      return '0x${hex.substring(2)}';
    } catch (_) {
      // Fallback nếu không có toARGB32() hoặc lỗi
      return 'white';
    }
  }

  @override
  void buildConcatInput(FfmpegInputArgs inputs, List<String> paths, String tempDir, int index) {
    final concatFile = File('$tempDir/concat_$index.txt');
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
