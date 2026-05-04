import 'dart:async';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/execution_result.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/ffmpeg_options.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/engine/video_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/toolkit/video_toolkit.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/metadata/video_metadata_analyzer.dart';
import 'dart:io';


abstract class BaseVideoBatchEngine implements VideoBatchEngine {
  final VideoHardwareCapabilityResolver hardwareResolver;
  final VideoToolkit toolkit;
  final VideoMetadataAnalyzer _metadataAnalyzer;
  late GpuInfo gpuInfo;

  BaseVideoBatchEngine({
    required this.hardwareResolver,
    required this.toolkit,
    required VideoMetadataAnalyzer metadataAnalyzer,
  }) : _metadataAnalyzer = metadataAnalyzer;


  @override
  Future<void> initialize() async {
    gpuInfo = hardwareResolver.gpuInfo!;
  }

  @override
  Future<ExecutionResult> cutSegment({
    required SegmentRequest request,
    required String outputPath,
    required VideoBatchExecutionContext context,
    void Function(String)? onLog,
  }) async {
    if (!await File(request.sourcePath).exists()) {
      onLog?.call('  ❌ Lỗi: Không tìm thấy file nguồn ${request.sourcePath}');
      return ExecutionResult(success: false);
    }


    final probe = await _metadataAnalyzer.probeSourceVideo(request.sourcePath);
    final isHdr = _metadataAnalyzer.isHdr(
      transfer: probe.colorInfo.transfer, 
      pixFmt: probe.colorInfo.pixFmt
    );

    final FfmpegInputArgs inputs = FfmpegInputArgs();
    _appendInputFlags(inputs);
    _appendSeekAndInput(inputs, request);
    _appendAudioSource(inputs, request);

    final FilterPipe vf = buildSegmentFilter(request, isHdr: isHdr);

    final List<String> args = [

      '-hide_banner', '-y',
      ...inputs.toArgs(),
      '-t', request.duration.toStringAsFixed(3),
      '-vf', vf.toString(),
    ];

    _appendMappingAndAudio(args, request);
    _appendOutputSettings(args, request);
    args.add(outputPath);

    return toolkit.runToolkit(args, context, onLog: onLog);
  }

  void _appendInputFlags(FfmpegInputArgs inputs) {
    if (gpuInfo.hwaccel != null) {
      inputs.addFlag('-hwaccel', gpuInfo.hwaccel!);
      if (gpuInfo.outputFormat != null) {
        inputs.addFlag('-hwaccel_output_format', gpuInfo.outputFormat!);
      }
    }
  }

  void _appendSeekAndInput(FfmpegInputArgs inputs, SegmentRequest request) {
    inputs.addAll([
      '-ss', request.startTime.toStringAsFixed(3),
      '-fflags', '+genpts+igndts',
      '-i', request.sourcePath,
    ]);
  }

  void _appendAudioSource(FfmpegInputArgs inputs, SegmentRequest request) {
    if (!request.hasAudio) {
      inputs.addInput('anullsrc=r=44100:cl=stereo', format: 'lavfi');
    }
  }

  void _appendMappingAndAudio(List<String> args, SegmentRequest request) {
    if (!request.hasAudio) {
      args.addAll(['-map', '0:v:0', '-map', '1:a:0', '-c:a', 'aac', '-shortest']);
    } else {
      args.addAll(['-af', 'aresample=44100', '-c:a', 'aac']);
    }
  }

  void _appendOutputSettings(List<String> args, SegmentRequest request) {
    args.addAll([
      '-r', '30',
      '-pix_fmt', toolkit.getPreferredPixelFormat(),
      '-colorspace', 'bt709',
      '-color_trc', 'bt709',
      '-color_primaries', 'bt709',
      ...getSegmentEncoderArgs(request).toArgs(),
      '-movflags', '+faststart',
      '-avoid_negative_ts', 'make_zero',
      '-map_metadata', '-1',
    ]);
  }


  @override
  Future<ExecutionResult> renderVideo({
    required CompositionPlan plan,
    required VideoBatchExecutionContext context,
    void Function(double)? onProgress,
    void Function(String)? onLog,
  }) async {
    final List<String> args = [
      '-hide_banner', '-y',
      ...getCompositionInputArgs(plan).toArgs(),
    ];

    // Build filter complex using high-level toolkit methods
    final filterComplex = StringBuffer();
    filterComplex.write('${toolkit.buildBaseFilter(plan)}[bg];');
    
    // Add color grading
    filterComplex.write('[bg]${toolkit.buildColorGradingChain(plan)}[colored];');
    
    // Add Overlays
    filterComplex.write(toolkit.buildOverlayChain(plan, '[colored]'));
    filterComplex.write('[video_out];'); // Target output label for video
    
    // Add Audio
    filterComplex.write(toolkit.buildAudioMixChain(plan));

    args.addAll([
      '-filter_complex', filterComplex.toString(),
      '-map', '[video_out]',
      '-map', '[mixed_a]',
      '-r', '30', // Đảm bảo output cuối cùng là 30fps
      ...getEncoderArgs(plan).toArgs(),
      plan.finalOutputPath,
    ]);

    return toolkit.runToolkit(
      args, 
      context, 
      onLog: onLog, 
      onProgress: onProgress,
      targetDuration: plan.params.targetDuration,
    );
  }

  @override
  String buildOverlayFilter(CompositionPlan plan) => toolkit.buildOverlayChain(plan, '[colored]');

  @override
  String buildAudioFilter(CompositionPlan plan) => toolkit.buildAudioMixChain(plan);

  @override
  String buildBaseVideoFilter(CompositionPlan plan) => toolkit.buildBaseFilter(plan);

  @override
  String buildColorFilter(CompositionPlan plan) => toolkit.buildColorGradingChain(plan);

  /// Các phương thức abstract cho các bước nhỏ
  FilterPipe buildSegmentFilter(SegmentRequest request, {required bool isHdr});
  EncoderOptions getSegmentEncoderArgs(SegmentRequest request);



  FfmpegInputArgs getCompositionInputArgs(CompositionPlan plan);
  
  @override
  EncoderOptions getEncoderArgs(CompositionPlan plan);

  String colorToHex(dynamic color) {
    // color can be material Color or hex string
    if (color is String) return color;
    return '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
