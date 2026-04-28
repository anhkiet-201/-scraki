import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/ffmpeg_options.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/engine/base_video_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/nvidia/nvidia_toolkit.dart';

class NvidiaBatchEngine extends BaseVideoBatchEngine {
  NvidiaBatchEngine({
    required super.hardwareResolver,
  }) : super(
          toolkit: NvidiaToolkit(hardwareResolver),
        );

  @override
  FfmpegInputArgs getSegmentInputArgs(SegmentRequest request) {
    final inputs = FfmpegInputArgs();
    if (gpuInfo.hwaccel != null) inputs.addFlag('-hwaccel', gpuInfo.hwaccel!);
    if (gpuInfo.outputFormat != null) inputs.addFlag('-hwaccel_output_format', gpuInfo.outputFormat!);
    return inputs;
  }

  @override
  FilterPipe buildSegmentFilter(SegmentRequest request) {
    final pipe = FilterPipe();
    pipe.add(toolkit.scale(1080, 1920));
    if (request.hflip) pipe.add(toolkit.hflip());
    pipe.add('format=${gpuInfo.preferredPixFmt}');
    return pipe;
  }

  @override
  EncoderOptions getSegmentEncoderArgs(SegmentRequest request) {
    return NvidiaNvencOptions(bitrate: '10M', preset: 'p1', cq: '20');
  }

  @override
  FfmpegInputArgs getCompositionInputArgs(CompositionPlan plan) {
    final inputs = FfmpegInputArgs();
    if (gpuInfo.hwaccel != null) inputs.addFlag('-hwaccel', gpuInfo.hwaccel!);
    if (gpuInfo.outputFormat != null) inputs.addFlag('-hwaccel_output_format', gpuInfo.outputFormat!);
    
    // 1. Video Segments (Concat file)
    toolkit.buildConcatInput(inputs, plan.segmentPaths, plan.outputDir, plan.outputIndex);

    // 2. Custom Audio
    if (plan.hasCustomAudio) {
      inputs.addInput(plan.config.customAudioPath!);
    }

    // 3. Ambient Audio
    if (plan.hasAmbientAudio) {
      inputs.addInput(plan.ambientAudioPath!);
    }

    // 4. Image Overlays
    for (final img in plan.config.imageOverlays) {
      if (img.localPath != null) inputs.addInput(img.localPath!);
    }

    // 5. Text Overlays (PNGs)
    for (final path in plan.textOverlayPaths) {
      inputs.addInput(path);
    }

    return inputs;
  }

  @override
  EncoderOptions getEncoderArgs(CompositionPlan plan) {
    return NvidiaNvencOptions(bitrate: '12M', preset: 'p4', cq: '24');
  }
}
