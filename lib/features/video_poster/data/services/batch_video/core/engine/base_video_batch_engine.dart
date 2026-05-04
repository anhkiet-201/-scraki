import 'dart:async';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/execution_result.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/ffmpeg_options.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/engine/video_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/toolkit/composition.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/toolkit/video_toolkit.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/metadata/video_metadata_analyzer.dart';
import 'dart:io';

/// Base implementation of [VideoBatchEngine] providing common orchestration logic.
/// 
/// This class handles the standard FFmpeg command structure while delegating 
/// platform-specific filter generation to a [Composition] engine.
/// 
/// [C] specifies the [Composition] type.
/// [T] specifies the [VideoToolkit] type.
abstract class BaseVideoBatchEngine<C extends Composition<T>, T extends VideoToolkit> implements VideoBatchEngine {
  /// The resolver used to identify hardware capabilities.
  final VideoHardwareCapabilityResolver hardwareResolver;
  /// The composition orchestrator that builds filter chains.
  final C composition;
  final VideoMetadataAnalyzer _metadataAnalyzer;
  /// Cached hardware information.
  late GpuInfo gpuInfo;

  BaseVideoBatchEngine({
    required this.hardwareResolver,
    required this.composition,
    required VideoMetadataAnalyzer metadataAnalyzer,
  }) : _metadataAnalyzer = metadataAnalyzer;

  /// Shorthand to access the atomic toolkit via the composition engine.
  T get toolkit => composition.toolkit;

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
      onLog?.call('  ❌ Error: Source file not found ${request.sourcePath}');
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

    return composition.execute(args, context, onLog: onLog);
  }

  /// Appends hardware acceleration flags to the input arguments.
  void _appendInputFlags(FfmpegInputArgs inputs) {
    if (gpuInfo.hwaccel != null) {
      inputs.addFlag('-hwaccel', gpuInfo.hwaccel!);
      if (gpuInfo.outputFormat != null) {
        inputs.addFlag('-hwaccel_output_format', gpuInfo.outputFormat!);
      }
    }
  }

  /// Appends seeking and primary input path to the arguments.
  void _appendSeekAndInput(FfmpegInputArgs inputs, SegmentRequest request) {
    inputs.addAll([
      '-ss', request.startTime.toStringAsFixed(3),
      '-fflags', '+genpts+igndts',
      '-i', request.sourcePath,
    ]);
  }

  /// Appends null audio source if the segment should be silent.
  void _appendAudioSource(FfmpegInputArgs inputs, SegmentRequest request) {
    if (!request.hasAudio) {
      inputs.addInput('anullsrc=r=44100:cl=stereo', format: 'lavfi');
    }
  }

  /// Configures mapping and audio encoding based on audio presence.
  void _appendMappingAndAudio(List<String> args, SegmentRequest request) {
    if (!request.hasAudio) {
      args.addAll(['-map', '0:v:0', '-map', '1:a:0', '-c:a', 'aac', '-shortest']);
    } else {
      args.addAll(['-af', 'aresample=44100', '-c:a', 'aac']);
    }
  }

  /// Appends final output parameters (FPS, pixel format, encoder).
  void _appendOutputSettings(List<String> args, SegmentRequest request) {
    args.addAll([
      '-r', '30',
      '-pix_fmt', composition.getPreferredPixelFormat(),
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

    // Build filter complex using high-level composition methods
    final filterComplex = StringBuffer();
    filterComplex.write('${composition.buildBaseFilter(plan)}[bg];');
    
    // Add color grading
    filterComplex.write('[bg]${composition.buildColorGradingChain(plan)}[colored];');
    
    // Add Overlays
    filterComplex.write(composition.buildOverlayChain(plan, '[colored]'));
    filterComplex.write('[video_out];'); // Target output label for video
    
    // Add Audio
    filterComplex.write(composition.buildAudioMixChain(plan));

    args.addAll([
      '-filter_complex', filterComplex.toString(),
      '-map', '[video_out]',
      '-map', '[mixed_a]',
      '-r', '30', // Force 30fps final output
      ...getEncoderArgs(plan).toArgs(),
      plan.finalOutputPath,
    ]);

    return composition.execute(
      args, 
      context, 
      onLog: onLog, 
      onProgress: onProgress,
      targetDuration: plan.params.targetDuration,
    );
  }

  @override
  String buildOverlayFilter(CompositionPlan plan) => composition.buildOverlayChain(plan, '[colored]');

  @override
  String buildAudioFilter(CompositionPlan plan) => composition.buildAudioMixChain(plan);

  @override
  String buildBaseVideoFilter(CompositionPlan plan) => composition.buildBaseFilter(plan);

  @override
  String buildColorFilter(CompositionPlan plan) => composition.buildColorGradingChain(plan);

  /// Implementers must provide the platform-specific segment filter chain.
  FilterPipe buildSegmentFilter(SegmentRequest request, {required bool isHdr});
  /// Implementers must provide encoder arguments for segments.
  EncoderOptions getSegmentEncoderArgs(SegmentRequest request);

  /// Implementers must provide input arguments for the final composition.
  FfmpegInputArgs getCompositionInputArgs(CompositionPlan plan);
  
  @override
  EncoderOptions getEncoderArgs(CompositionPlan plan);

  /// Helper to convert various color inputs to FFmpeg-compatible hex format.
  String colorToHex(dynamic color) {
    if (color is String) return color;
    // Assume it is a Flutter Color or compatible integer representation
    return '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
