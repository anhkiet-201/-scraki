import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/execution_result.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/ffmpeg_options.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/toolkit/video_toolkit.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';

/// Interface defining the core composition capabilities for video rendering.
///
/// [T] specifies the type of [VideoToolkit] used by this composition to generate
/// atomic filter strings.
///
/// Implementations of this interface (e.g., Apple, Nvidia, CPU) provide hardware-specific
/// logic for constructing FFmpeg filter chains and input arguments.
abstract interface class Composition<T extends VideoToolkit> {
  /// The atomic toolkit used by this composition to generate individual filter strings.
  T get toolkit;
  /// Builds the input arguments for concatenating multiple video segments.
  ///
  /// [inputs] The FFmpeg argument builder to append to.
  /// [paths] List of file paths to the video segments.
  /// [tempDir] Temporary directory for intermediate files if needed.
  /// [index] Current batch or segment index for unique identification.
  void buildConcatInput(FfmpegInputArgs inputs, List<String> paths, String tempDir, int index);

  /// Builds input arguments for individual video segments.
  ///
  /// This is typically used when segments are processed independently before being merged.
  void buildIndividualInputs(FfmpegInputArgs inputs, List<String> segmentPaths);

  /// Constructs the FFmpeg filter chain for overlays (e.g., watermarks, images).
  ///
  /// [plan] The composition plan containing overlay details.
  /// [inputLabel] The label of the input stream to apply overlays onto.
  /// Returns a string representing the filter chain segment.
  String buildOverlayChain(CompositionPlan plan, String inputLabel);

  /// Constructs the FFmpeg filter chain for audio mixing and processing.
  ///
  /// [plan] The composition plan containing audio configuration.
  /// Returns a string representing the audio filter chain.
  String buildAudioMixChain(CompositionPlan plan);

  /// Constructs the base video filter chain (scaling, padding, framerate conversion).
  ///
  /// [plan] The composition plan containing target dimensions and format.
  /// Returns a string representing the base filter chain.
  String buildBaseFilter(CompositionPlan plan);

  /// Constructs the filter chain for color grading (LUTs, brightness, contrast).
  ///
  /// [plan] The composition plan containing color adjustment parameters.
  /// Returns a string representing the color grading filter chain.
  String buildColorGradingChain(CompositionPlan plan);

  /// Returns the preferred pixel format for this specific hardware/engine.
  ///
  /// This ensures that the output format is compatible with hardware encoders
  /// (e.g., nv12 for Nvidia, videotoolbox for Apple).
  String getPreferredPixelFormat();

  /// Executes the video processing task (FFmpeg command or API call).
  ///
  /// [args] List of command line arguments for the toolkit.
  /// [context] Execution context to manage process lifecycle and cancellation.
  /// [onLog] Optional callback for capturing execution logs.
  /// [onProgress] Optional callback for tracking processing progress (0.0 to 1.0).
  /// [targetDuration] The expected duration of the output video in seconds, used for progress calculation.
  /// Returns an [ExecutionResult] indicating success or failure.
  Future<ExecutionResult> execute(
    List<String> args,
    VideoBatchExecutionContext context, {
    void Function(String)? onLog,
    void Function(double)? onProgress,
    int? targetDuration,
    Duration? timeout,
  });
}