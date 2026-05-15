import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/ffmpeg_options.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/engine/base_video_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/cpu/cpu_composition.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/cpu/cpu_toolkit.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';

/// Software-based batch video engine (CPU only).
/// 
/// Uses libx264 for encoding and standard FFmpeg filters for processing. 
/// Used as a fallback when no compatible GPU is detected.
class CpuBatchEngine extends BaseVideoBatchEngine<CpuComposition, CpuToolkit> {
  CpuBatchEngine({
    required super.hardwareResolver,
    required super.metadataAnalyzer,
  }) : super(
          composition: CpuComposition(
            hardwareResolver: hardwareResolver,
            toolkit: CpuToolkit(),
          ),
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
    return CpuLibx264Options(preset: 'ultrafast', crf: '20');
  }

  @override
  FfmpegInputArgs getCompositionInputArgs(CompositionPlan plan) {
    final inputs = FfmpegInputArgs();
    
    // 1. Video Segments (Concat Demuxer)
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
    return CpuLibx264Options(
      preset: 'medium',
      crf: '21',
      bFrames: plan.params.bFrames,
    );
  }
}
