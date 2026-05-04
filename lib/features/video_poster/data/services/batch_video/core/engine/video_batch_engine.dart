import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/execution_result.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/ffmpeg_options.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';

/// Defines the contract for a video batch rendering engine.
/// 
/// Engines are responsible for two main phases:
/// 1. Cutting segments: Processing individual video slices from source files.
/// 2. Rendering: Composing segments, overlays, and audio into a final unique video.
abstract class VideoBatchEngine {
  /// Initializes the engine, typically detecting hardware capabilities.
  Future<void> initialize();

  /// Processes a single video segment request.
  /// 
  /// This includes trimming, scaling, and applying basic transformations 
  /// before the segment is used in the final composition.
  Future<ExecutionResult> cutSegment({
    required SegmentRequest request,
    required String outputPath,
    required VideoBatchExecutionContext context,
    void Function(String)? onLog,
  });

  /// Composes the final video based on a comprehensive [CompositionPlan].
  /// 
  /// This is the heavy-lifting phase that applies overlays, audio mixing, 
  /// Ken Burns effects, and final encoding.
  Future<ExecutionResult> renderVideo({
    required CompositionPlan plan,
    required VideoBatchExecutionContext context,
    void Function(double)? onProgress,
    void Function(String)? onLog,
  });

  /// Builds the base video filter chain (scaling, padding, speed).
  String buildBaseVideoFilter(CompositionPlan plan);
  /// Builds the color grading filter chain.
  String buildColorFilter(CompositionPlan plan);
  /// Builds the overlay (images/text) filter chain.
  String buildOverlayFilter(CompositionPlan plan);
  /// Builds the audio mixing filter chain.
  String buildAudioFilter(CompositionPlan plan);
  
  /// Returns the encoder-specific arguments for final rendering.
  EncoderOptions getEncoderArgs(CompositionPlan plan);
}
