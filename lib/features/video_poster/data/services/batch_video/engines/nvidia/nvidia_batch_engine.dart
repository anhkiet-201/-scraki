import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/ffmpeg_options.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/engine/base_video_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/nvidia/nvidia_composition.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/nvidia/nvidia_toolkit.dart';

/// NVIDIA-optimized batch video engine.
/// 
/// Uses NVENC for hardware-accelerated encoding and CUDA for high-performance 
/// video filtering (scaling, flipping, and overlays).
class NvidiaBatchEngine extends BaseVideoBatchEngine<NvidiaComposition, NvidiaToolkit> {
  NvidiaBatchEngine({
    required super.hardwareResolver,
    required super.metadataAnalyzer,
  }) : super(
          composition: NvidiaComposition(hardwareResolver: hardwareResolver, toolkit: NvidiaToolkit()),
        );

  @override
  FilterPipe buildSegmentFilter(SegmentRequest request, {required bool isHdr}) {
    final pipe = FilterPipe();
    pipe.add(toolkit.scale(1080, 1920, expression: '1080:1920:force_original_aspect_ratio=decrease'));
    pipe.add(toolkit.pad(1080, 1920));
    if (request.hflip) pipe.add(toolkit.hflip());
    pipe.add('format=${composition.getPreferredPixelFormat()}');
    return pipe;
  }

  @override
  EncoderOptions getSegmentEncoderArgs(SegmentRequest request) {
    return NvidiaNvencOptions(bitrate: '12M', preset: 'p1', cq: '20');
  }

  @override
  FfmpegInputArgs getCompositionInputArgs(CompositionPlan plan) {
    final inputs = FfmpegInputArgs();
    if (gpuInfo.hwaccel != null) {
      inputs.addFlag('-hwaccel', gpuInfo.hwaccel!);
      if (gpuInfo.outputFormat != null) {
        inputs.addFlag('-hwaccel_output_format', gpuInfo.outputFormat!);
      }
    }
    
    // 1. Video Segments (Using Concat Demuxer for 100% stability)
    composition.buildConcatInput(inputs, plan.segmentPaths, plan.tempDir, plan.outputIndex);

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
      if (img.localPath != null) {
        inputs.addInput(
          img.localPath!, 
          extraArgs: img.isGif ? ['-ignore_loop', '0'] : ['-loop', '1'],
        );
      }
    }

    // 5. Text Overlays (PNGs)
    for (final path in plan.textOverlayPaths) {
      inputs.addInput(path, extraArgs: ['-loop', '1']);
    }

    return inputs;
  }

  @override
  EncoderOptions getEncoderArgs(CompositionPlan plan) {
    return NvidiaNvencOptions(
      bitrate: '12M',
      preset: 'p4',
      cq: '24',
      bFrames: plan.params.bFrames,
    );
  }
}
