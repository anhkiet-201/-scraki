import 'dart:io';
import 'package:injectable/injectable.dart';
import '../../models/batch_video_models.dart';
import '../../models/video_batch_execution_context.dart';
import '../hardware/video_hardware_capability_resolver.dart';
import '../metadata/video_metadata_analyzer.dart';
import '../encoding/video_segment_engine.dart';
import '../encoding/video_segment_engine_factory.dart';
import 'video_segment_processor.dart';

@LazySingleton(as: VideoSegmentProcessor)
class VideoSegmentProcessorImpl implements VideoSegmentProcessor {
  final VideoHardwareCapabilityResolver _hardwareResolver;
  final VideoMetadataAnalyzer _metadataAnalyzer;

  VideoSegmentProcessorImpl(this._hardwareResolver, this._metadataAnalyzer);

  @override
  Future<void> runSegmentCut({
    required String input,
    required double startSeconds,
    required double duration,
    required String output,
    required bool hflip,
    required bool hasAudio,
    required String processName,
    required VideoBatchExecutionContext context,
    void Function(String)? onLogMsg,
  }) async {
    if (!await File(input).exists()) {
      onLogMsg?.call('  ❌ [$processName] Lỗi: Không tìm thấy file nguồn');
      return;
    }

    final probeResult = await _metadataAnalyzer.probeSourceVideo(input);
    final hdr = _metadataAnalyzer.isHdr(
      transfer: probeResult.colorInfo.transfer, 
      pixFmt: probeResult.colorInfo.pixFmt
    );

    final gpuInfo = await _hardwareResolver.getGpuInfo();
    final engine = VideoSegmentEngineFactory.getEngine(gpuInfo);

    final vfFilter = engine.buildSegmentFilter(
      isHdr: hdr,
      hflip: hflip,
      width: 1080,
      height: 1920,
      gpuInfo: gpuInfo,
    );

    final afFilter = hasAudio ? 'aresample=44100' : 'anullsrc';

    final success = await _runWithFilter(
      vfFilter,
      afFilter,
      gpuInfo,
      engine: engine,
      input: input,
      startSeconds: startSeconds,
      duration: duration,
      output: output,
      processName: processName,
      context: context,
      onLogMsg: onLogMsg,
    );

    if (!success && !context.cancelled) {
      // Fallback logic
      final fallbackGpuInfo = (
        encoder: 'libx264',
        hwaccel: null,
        scaleFilter: null,
        outputFormat: null,
        hasZscale: gpuInfo.hasZscale,
        hasCudaFilters: false,
        preferredPixFmt: 'yuv420p',
        maxConcurrentEncodes: gpuInfo.maxConcurrentEncodes,
      );
      
      final fallbackEngine = VideoSegmentEngineFactory.getEngine(fallbackGpuInfo);
      
      onLogMsg?.call('  ⚠️ [$processName] Encode GPU thất bại, thử fallback CPU...');
      
      final fallbackFilter = fallbackEngine.buildSegmentFilter(
        isHdr: hdr,
        hflip: hflip,
        width: 1080,
        height: 1920,
        gpuInfo: fallbackGpuInfo,
      );

      await _runWithFilter(
        fallbackFilter,
        afFilter,
        fallbackGpuInfo,
        engine: fallbackEngine,
        input: input,
        startSeconds: startSeconds,
        duration: duration,
        output: output,
        processName: processName,
        context: context,
        onLogMsg: onLogMsg,
      );
    }
  }

  Future<bool> _runWithFilter(
    String vf,
    String af,
    GpuInfo gpuInfo, {
    required VideoSegmentEngine engine,
    required String input,
    required double startSeconds,
    required double duration,
    required String output,
    required String processName,
    required VideoBatchExecutionContext context,
    void Function(String)? onLogMsg,
  }) async {
    try {
      final List<String> args = ['-hide_banner', '-y'];
      if (gpuInfo.hwaccel != null) {
        args.addAll(['-hwaccel', gpuInfo.hwaccel!]);
        if (gpuInfo.outputFormat != null) args.addAll(['-hwaccel_output_format', gpuInfo.outputFormat!]);
      }
      args.addAll(['-ss', startSeconds.toStringAsFixed(3), '-fflags', '+genpts+igndts', '-i', input]);
      if (af == 'anullsrc') args.addAll(['-f', 'lavfi', '-i', 'anullsrc=r=44100:cl=stereo']);
      args.addAll(['-t', duration.toStringAsFixed(3), '-vf', vf]);
      
      if (af == 'anullsrc') {
        args.addAll(['-map', '0:v:0', '-map', '1:a:0', '-c:a', 'aac', '-shortest']);
      } else {
        args.addAll(['-af', af, '-c:a', 'aac']);
      }
      
      args.addAll([
        '-pix_fmt', engine.getPreferredPixFmt(gpuInfo),
        '-colorspace', 'bt709',
        '-color_trc', 'bt709',
        '-color_primaries', 'bt709',
      ]);

      args.addAll(engine.getSegmentEncoderArgs(gpuInfo));
      args.addAll(['-movflags', '+faststart', '-avoid_negative_ts', 'make_zero', '-map_metadata', '-1', output]);

      final process = await Process.start(_hardwareResolver.ffmpegBin, args);
      context.addProcess(process);

      final stderrList = <String>[];
      process.stderr.listen((data) {
        final out = String.fromCharCodes(data);
        for (final line in out.split('\n')) {
          if (line.trim().isNotEmpty) {
            stderrList.add(line);
            if (stderrList.length > 15) stderrList.removeAt(0);
          }
        }
      });

      final exitCode = await process.exitCode;
      context.removeProcess(process);

      if (exitCode != 0 || !File(output).existsSync()) {
        final errorLog = stderrList.join('\n');
        if (errorLog.isNotEmpty && !context.cancelled) {
          onLogMsg?.call('  ❌ [$processName] FFmpeg lỗi (exit $exitCode):\n$errorLog\n (Filters: vf=$vf)');
        }
        return false;
      }
      return true;
    } catch (e) {
      if (!context.cancelled) onLogMsg?.call('  ❌ [$processName] Exception: $e');
      return false;
    }
  }
}
