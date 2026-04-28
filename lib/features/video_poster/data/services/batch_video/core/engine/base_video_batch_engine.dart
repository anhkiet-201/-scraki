import 'dart:async';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/execution_result.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/ffmpeg_options.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/engine/video_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/toolkit/video_toolkit.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart';

abstract class BaseVideoBatchEngine implements VideoBatchEngine {
  final VideoHardwareCapabilityResolver hardwareResolver;
  final VideoToolkit toolkit;
  late GpuInfo gpuInfo;

  BaseVideoBatchEngine({
    required this.hardwareResolver,
    required this.toolkit,
  });

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
    final List<String> args = [
      '-hide_banner', '-y',
      ...getSegmentInputArgs(request).toArgs(),
      '-i', request.sourcePath,
      '-ss', request.startTime.toStringAsFixed(3),
      '-t', request.duration.toStringAsFixed(3),
      '-filter_complex', buildSegmentFilter(request).toString(),
      ...getSegmentEncoderArgs(request).toArgs(),
      '-avoid_negative_ts', 'make_zero',
      outputPath,
    ];

    return toolkit.runToolkit(args, context, onLog: onLog);
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
  FfmpegInputArgs getSegmentInputArgs(SegmentRequest request);
  FilterPipe buildSegmentFilter(SegmentRequest request);
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
