import 'dart:io';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/engine/video_batch_engine.dart';

class PipelineContext {
  final BatchVideoConfig config;
  late GpuInfo gpuInfo;
  late VideoBatchEngine engine;
  final VideoBatchExecutionContext executionContext = VideoBatchExecutionContext();
  
  // State
  final List<String> validSourceVideos = [];
  final Map<String, int> videoDurations = {};
  final Map<String, bool> videoHasAudio = {};
  final List<String> tempAmbientAudioPaths = [];
  
  final Map<int, List<SegmentRequest>> videoPlans = {};
  final Set<SegmentRequest> allUniqueSegments = {};
  final Map<SegmentRequest, String> segmentFileMap = {};
  
  late Directory tempDir;
  late String outputDir;

  PipelineContext({required this.config});

  bool get cancelled => executionContext.cancelled;
  
  void cancel() {
    executionContext.cancel();
  }
}
