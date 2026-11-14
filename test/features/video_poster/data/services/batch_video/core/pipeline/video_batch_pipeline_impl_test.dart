import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/pipeline/video_batch_pipeline_impl.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/audio/ambient_audio_provider.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/metadata/video_metadata_analyzer.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';

class _FakeHardwareResolver implements VideoHardwareCapabilityResolver {
  bool shouldThrow = false;

  @override
  String get ffmpegBin => 'ffmpeg';

  @override
  String get ffprobeBin => 'ffprobe';

  @override
  GpuInfo? gpuInfo;

  @override
  Future<bool> checkFfmpeg() async => true;

  @override
  void clearCache() => gpuInfo = null;

  @override
  Future<GpuInfo> resolve() async {
    if (shouldThrow) {
      throw StateError('Simulated hardware probe failure');
    }
    gpuInfo = (
      name: 'Test CPU',
      encoder: 'libx264',
      hwaccel: null,
      scaleFilter: null,
      outputFormat: null,
      hasZscale: false,
      hasCudaFilters: false,
      preferredPixFmt: 'yuv420p',
      maxConcurrentEncodes: 2,
    );
    return gpuInfo!;
  }
}

class _FakeMetadataAnalyzer implements VideoMetadataAnalyzer {
  @override
  void clearCache() {}

  @override
  bool isHdr({required String transfer, required String pixFmt}) => false;

  @override
  Future<ProbeResult> probeSourceVideo(String path) async => (
        duration: 15,
        hasAudio: true,
        colorInfo: (transfer: 'bt709', primaries: 'bt709', pixFmt: 'yuv420p'),
      );
}

class _FakeAmbientAudioProvider implements AmbientAudioProvider {
  @override
  Future<List<String>> fetchRandomAmbientAudios(
    int count,
    List<String> tags, {
    void Function(String)? onLog,
  }) async =>
      [];
}

void main() {
  group('VideoBatchPipelineImpl cancel and re-export lifecycle', () {
    late Directory tempOutputBase;
    late _FakeHardwareResolver hardwareResolver;
    late VideoBatchPipelineImpl pipeline;

    setUp(() async {
      tempOutputBase = await Directory.systemTemp.createTemp('scraki_test_');
      hardwareResolver = _FakeHardwareResolver();
      pipeline = VideoBatchPipelineImpl(
        hardwareResolver,
        _FakeMetadataAnalyzer(),
        _FakeAmbientAudioProvider(),
      );
    });

    tearDown(() async {
      await pipeline.cleanup();
      if (await tempOutputBase.exists()) {
        await tempOutputBase.delete(recursive: true);
      }
    });

    test('plan resets processing state on exception so next plan succeeds', () async {
      hardwareResolver.shouldThrow = true;
      final config = BatchVideoConfig(
        outputCount: 1,
        outputDir: tempOutputBase.path,
        generateAmbientAudio: false,
      );

      await expectLater(
        () => pipeline.plan(sourceVideoPaths: ['/tmp/a.mp4'], config: config),
        throwsStateError,
      );

      hardwareResolver.shouldThrow = false;
      await pipeline.plan(sourceVideoPaths: ['/tmp/a.mp4'], config: config);

      // Should not throw LateInitializationError and should be ready to clean up.
      expect(pipeline.outputDir, isNull);
    });

    test('cancel followed by cleanup and a new plan works cleanly', () async {
      final config = BatchVideoConfig(
        outputCount: 1,
        outputDir: tempOutputBase.path,
        generateAmbientAudio: false,
      );

      await pipeline.plan(sourceVideoPaths: ['/tmp/a.mp4'], config: config);
      pipeline.cancel();
      await pipeline.executeCutSegments();
      await pipeline.executeRender();
      await pipeline.cleanup();

      expect(pipeline.outputDir, isNull);

      // Start a second run immediately after cancelling and cleaning up.
      await pipeline.plan(sourceVideoPaths: ['/tmp/a.mp4'], config: config);
      expect(hardwareResolver.gpuInfo, isNotNull);
    });
  });
}
