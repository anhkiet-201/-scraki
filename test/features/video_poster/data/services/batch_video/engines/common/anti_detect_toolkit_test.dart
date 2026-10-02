import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/core/domain/composition_plan.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/common/ffmpeg_composition.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/common/ffmpeg_toolkit.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/engines/hardware/video_hardware_capability_resolver.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';

class MockHardwareResolver implements VideoHardwareCapabilityResolver {
  @override
  String get ffmpegBin => 'ffmpeg';

  @override
  String get ffprobeBin => 'ffprobe';

  @override
  GpuInfo get gpuInfo => (
        name: 'cpu',
        encoder: 'libx264',
        hwaccel: null,
        scaleFilter: 'scale',
        outputFormat: null,
        hasZscale: false,
        hasCudaFilters: false,
        preferredPixFmt: 'yuv420p',
        maxConcurrentEncodes: 1,
      );

  @override
  Future<GpuInfo> resolve() async => gpuInfo;

  @override
  Future<bool> checkFfmpeg() async => true;

  @override
  void clearCache() {}
}

void main() {
  group('Anti-Detect VideoToolkit & Composition Tests', () {
    late BaseFfmpegToolkit toolkit;
    late BaseFfmpegComposition composition;

    setUp(() {
      toolkit = BaseFfmpegToolkit();
      composition = BaseFfmpegComposition(
        hardwareResolver: MockHardwareResolver(),
        toolkit: toolkit,
      );
    });

    test('noise() filter generates correct temporal film grain string', () {
      final noiseFilter = toolkit.noise(4.5);
      expect(noiseFilter, 'noise=alls=5:allf=t+u');

      final clampedLow = toolkit.noise(0.2);
      expect(clampedLow, 'noise=alls=1:allf=t+u');

      final clampedHigh = toolkit.noise(150);
      expect(clampedHigh, 'noise=alls=100:allf=t+u');
    });

    test('microRotate() filter produces sub-degree rotation with valid canvas dimensions', () {
      final rotateFilter = toolkit.microRotate(0.25, ow: 1080, oh: 1920);
      expect(rotateFilter, contains('rotate=(0.25)*PI/180:c=black@0:ow=1080:oh=1920'));
    });

    test('eq() supports multi-channel gamma for color fingerprint disruption', () {
      final eqFilter = toolkit.eq(
        brightness: 0.015,
        contrast: 1.02,
        saturation: 1.03,
        gamma: 1.0,
        gammaR: 1.025,
        gammaG: 0.985,
        gammaB: 1.015,
      );
      expect(eqFilter, contains('gamma_r=1.0250'));
      expect(eqFilter, contains('gamma_g=0.9850'));
      expect(eqFilter, contains('gamma_b=1.0150'));
    });

    test('buildBaseFilter() integrates micro-rotation and sinusoidal camera pan', () {
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
          noiseIntensity: 5.0,
          microRotationAngle: 0.18,
          targetBitrateKbps: 9500,
        ),
        textOverlayPaths: [],
        hasCustomAudio: false,
        hasAmbientAudio: false,
      );

      final filter = composition.buildBaseFilter(plan);
      expect(filter, contains('rotate=(0.18)*PI/180'));
      expect(filter, contains('sin(2*PI*t/4)'));
      expect(filter, contains('cos(2*PI*t/4)'));
    });

    test('buildColorGradingChain() incorporates temporal noise and channel gamma', () {
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
          brightness: 0.01,
          contrast: 1.02,
          gopSize: 30,
          bFrames: 2,
          creationTime: '2026-10-01T00:00:00Z',
          audioProfile: AudioSpoofProfile.random(random),
          hueShift: 0.5,
          satFactor: 1.02,
          vignetteAngle: 0.05,
          zoomVal: 1.05,
          cropJitterX: 0.01,
          cropJitterY: 0.01,
          panStartX: 0.2,
          panStartY: 0.2,
          panEndX: 0.8,
          panEndY: 0.8,
          transitionDuration: 0.05,
          noiseIntensity: 6.0,
          microRotationAngle: 0.0,
          targetBitrateKbps: 9000,
          gammaR: 1.02,
          gammaG: 0.99,
          gammaB: 1.01,
        ),
        textOverlayPaths: [],
        hasCustomAudio: false,
        hasAmbientAudio: false,
      );

      final colorFilter = composition.buildColorGradingChain(plan);
      expect(colorFilter, contains('noise=alls=6:allf=t+u'));
      expect(colorFilter, contains('gamma_r=1.0200'));
      expect(colorFilter, contains('gamma_g=0.9900'));
      expect(colorFilter, contains('gamma_b=1.0100'));
    });
  });
}
