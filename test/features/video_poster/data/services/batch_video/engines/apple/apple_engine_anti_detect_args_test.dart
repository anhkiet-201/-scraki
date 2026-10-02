import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/execution_result.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/apple/apple_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/apple/apple_composition.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/apple/apple_toolkit.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/cpu/cpu_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/metadata/video_metadata_analyzer.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/nvidia/nvidia_batch_engine.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/video_batch_execution_context.dart';
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';

class MockHardwareResolver implements VideoHardwareCapabilityResolver {
  @override
  String get ffmpegBin => 'ffmpeg';

  @override
  String get ffprobeBin => 'ffprobe';

  @override
  GpuInfo get gpuInfo => (
        name: 'apple_videotoolbox',
        encoder: 'h264_videotoolbox',
        hwaccel: 'videotoolbox',
        scaleFilter: 'scale',
        outputFormat: null,
        hasZscale: false,
        hasCudaFilters: false,
        preferredPixFmt: 'nv12',
        maxConcurrentEncodes: 2,
      );

  @override
  Future<GpuInfo> resolve() async => gpuInfo;

  @override
  Future<bool> checkFfmpeg() async => true;

  @override
  void clearCache() {}
}

class MockMetadataAnalyzer implements VideoMetadataAnalyzer {
  @override
  bool isHdr({required String transfer, required String pixFmt}) => false;

  @override
  Future<ProbeResult> probeSourceVideo(String path) async {
    return (
      duration: 60,
      hasAudio: true,
      colorInfo: (
        transfer: 'bt709',
        primaries: 'bt709',
        pixFmt: 'yuv420p',
      ),
    );
  }

  @override
  void clearCache() {}
}

void main() {
  group('Engine Anti-Detect Args & Bitrate Tests', () {
    late AppleBatchEngine appleEngine;
    late NvidiaBatchEngine nvidiaEngine;
    late CpuBatchEngine cpuEngine;

    setUp(() {
      final hw = MockHardwareResolver();
      final meta = MockMetadataAnalyzer();
      appleEngine = AppleBatchEngine(hardwareResolver: hw, metadataAnalyzer: meta);
      nvidiaEngine = NvidiaBatchEngine(hardwareResolver: hw, metadataAnalyzer: meta);
      cpuEngine = CpuBatchEngine(hardwareResolver: hw, metadataAnalyzer: meta);
    });

    test('AppleBatchEngine uses plan targetBitrateKbps instead of hardcoded 12M', () {
      final random = Random(42);
      final plan = CompositionPlan(
        outputIndex: 1,
        segmentPaths: ['/tmp/seg1.mp4'],
        segmentDurations: [10.0],
        outputDir: '/tmp/output',
        tempDir: '/tmp',
        config: const BatchVideoConfig(),
        params: CompositionParams(
          targetDuration: 30,
          pts: 1.0,
          brightness: 0.0,
          contrast: 1.0,
          gopSize: 48,
          bFrames: 2,
          creationTime: '2026-10-01T00:00:00Z',
          audioProfile: AudioSpoofProfile.random(random),
          hueShift: 0.0,
          satFactor: 1.0,
          vignetteAngle: 0.05,
          zoomVal: 1.05,
          cropJitterX: 0.01,
          cropJitterY: 0.01,
          panStartX: 0.2,
          panStartY: 0.2,
          panEndX: 0.8,
          panEndY: 0.8,
          transitionDuration: 0.05,
          noiseIntensity: 4.0,
          microRotationAngle: 0.1,
          targetBitrateKbps: 8450,
        ),
        textOverlayPaths: [],
        hasCustomAudio: false,
        hasAmbientAudio: false,
      );

      final args = appleEngine.getEncoderArgs(plan).toArgs();
      expect(args, contains('-b:v'));
      expect(args, contains('8450k'));
      expect(args, contains('-bf'));
      expect(args, contains('2'));
    });

    test('NvidiaBatchEngine uses plan targetBitrateKbps', () {
      final random = Random(42);
      final plan = CompositionPlan(
        outputIndex: 1,
        segmentPaths: ['/tmp/seg1.mp4'],
        segmentDurations: [10.0],
        outputDir: '/tmp/output',
        tempDir: '/tmp',
        config: const BatchVideoConfig(),
        params: CompositionParams(
          targetDuration: 30,
          pts: 1.0,
          brightness: 0.0,
          contrast: 1.0,
          gopSize: 60,
          bFrames: 1,
          creationTime: '2026-10-01T00:00:00Z',
          audioProfile: AudioSpoofProfile.random(random),
          hueShift: 0.0,
          satFactor: 1.0,
          vignetteAngle: 0.05,
          zoomVal: 1.05,
          cropJitterX: 0.01,
          cropJitterY: 0.01,
          panStartX: 0.2,
          panStartY: 0.2,
          panEndX: 0.8,
          panEndY: 0.8,
          transitionDuration: 0.05,
          noiseIntensity: 4.0,
          microRotationAngle: 0.1,
          targetBitrateKbps: 11200,
        ),
        textOverlayPaths: [],
        hasCustomAudio: false,
        hasAmbientAudio: false,
      );

      final args = nvidiaEngine.getEncoderArgs(plan).toArgs();
      expect(args, contains('-b:v'));
      expect(args, contains('11200k'));
      expect(args, contains('-bf'));
      expect(args, contains('1'));
    });

    test('CpuBatchEngine applies varying CRF based on outputIndex', () {
      final random = Random(42);
      CompositionPlan createPlan(int idx) => CompositionPlan(
        outputIndex: idx,
        segmentPaths: ['/tmp/seg1.mp4'],
        segmentDurations: [10.0],
        outputDir: '/tmp/output',
        tempDir: '/tmp',
        config: const BatchVideoConfig(),
        params: CompositionParams(
          targetDuration: 30,
          pts: 1.0,
          brightness: 0.0,
          contrast: 1.0,
          gopSize: 30,
          bFrames: 2,
          creationTime: '2026-10-01T00:00:00Z',
          audioProfile: AudioSpoofProfile.random(random),
          hueShift: 0.0,
          satFactor: 1.0,
          vignetteAngle: 0.05,
          zoomVal: 1.05,
          cropJitterX: 0.01,
          cropJitterY: 0.01,
          panStartX: 0.2,
          panStartY: 0.2,
          panEndX: 0.8,
          panEndY: 0.8,
          transitionDuration: 0.05,
        ),
        textOverlayPaths: [],
        hasCustomAudio: false,
        hasAmbientAudio: false,
      );

      final args1 = cpuEngine.getEncoderArgs(createPlan(1)).toArgs();
      final args2 = cpuEngine.getEncoderArgs(createPlan(2)).toArgs();

      expect(args1, contains('-crf'));
      expect(args1, contains('21'));

      expect(args2, contains('-crf'));
      expect(args2, contains('22'));
    });

    test('renderVideo adds -map_metadata -1, clears encoder tag, and adds +faststart', () async {
      final executedArgs = <String>[];
      final mockComposition = MockCapturingComposition(
        hardwareResolver: MockHardwareResolver(),
        toolkit: AppleToolkit(),
        onExecute: (args) => executedArgs.addAll(args),
      );

      final testEngine = TestVideoBatchEngine(
        hardwareResolver: MockHardwareResolver(),
        metadataAnalyzer: MockMetadataAnalyzer(),
        customComposition: mockComposition,
      );

      final plan = CompositionPlan(
        outputIndex: 1,
        segmentPaths: ['/tmp/seg1.mp4'],
        segmentDurations: [10.0],
        outputDir: '/tmp/output',
        tempDir: '/tmp',
        config: const BatchVideoConfig(),
        params: CompositionParams(
          targetDuration: 30,
          pts: 1.0,
          brightness: 0.0,
          contrast: 1.0,
          gopSize: 30,
          bFrames: 2,
          creationTime: '2026-10-01T00:00:00Z',
          audioProfile: AudioSpoofProfile.random(Random(42)),
          hueShift: 0.0,
          satFactor: 1.0,
          vignetteAngle: 0.05,
          zoomVal: 1.05,
          cropJitterX: 0.01,
          cropJitterY: 0.01,
          panStartX: 0.2,
          panStartY: 0.2,
          panEndX: 0.8,
          panEndY: 0.8,
          transitionDuration: 0.05,
        ),
        textOverlayPaths: [],
        hasCustomAudio: false,
        hasAmbientAudio: false,
      );

      await testEngine.renderVideo(
        plan: plan,
        context: VideoBatchExecutionContext(),
      );

      expect(executedArgs, contains('-map_metadata'));
      final mapMetaIdx = executedArgs.indexOf('-map_metadata');
      expect(executedArgs[mapMetaIdx + 1], '-1');

      expect(executedArgs, contains('-metadata:g'));
      final metaIdx = executedArgs.indexOf('-metadata:g');
      expect(executedArgs[metaIdx + 1], 'encoder=');

      expect(executedArgs, contains('-movflags'));
      final movIdx = executedArgs.indexOf('-movflags');
      expect(executedArgs[movIdx + 1], '+faststart');
    });
  });
}

class MockCapturingComposition extends AppleComposition {
  final void Function(List<String>) onExecute;

  MockCapturingComposition({
    required super.hardwareResolver,
    required super.toolkit,
    required this.onExecute,
  });

  @override
  Future<ExecutionResult> execute(
    List<String> args,
    VideoBatchExecutionContext context, {
    void Function(String)? onLog,
    void Function(double)? onProgress,
    int? targetDuration,
    Duration? timeout,
  }) async {
    onExecute(args);
    return ExecutionResult.success('/tmp/out.mp4');
  }
}

class TestVideoBatchEngine extends AppleBatchEngine {
  TestVideoBatchEngine({
    required super.hardwareResolver,
    required super.metadataAnalyzer,
    required MockCapturingComposition customComposition,
  }) : _customComposition = customComposition;

  final MockCapturingComposition _customComposition;

  @override
  AppleComposition get composition => _customComposition;
}
