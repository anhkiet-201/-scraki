import 'dart:io';
import 'dart:math';
import 'package:scraki/features/video_poster/domain/entities/batch_video_config.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/mixins/batch_video_gpu_mixin.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/mixins/batch_video_probe_mixin.dart';
import 'package:scraki/features/video_poster/data/services/batch_video/mixins/batch_video_state_mixin.dart';
import 'package:path/path.dart' as p;

mixin BatchVideoSegmentMixin
    on BatchVideoGpuMixin, BatchVideoProbeMixin, BatchVideoStateMixin {
  List<SegmentRequest> generateSegmentPool({
    required List<String> validVideos,
    required Map<String, int> videoDurations,
    required Map<String, bool> videoHasAudio,
    required BatchVideoConfig config,
    required Random random,
    bool isRetry = false,
  }) {
    final pool = <SegmentRequest>[];
    final shuffledVideos = List<String>.from(validVideos)..shuffle(random);

    for (final src in shuffledVideos) {
      final srcDur = videoDurations[src]!.toDouble();
      double currentTime = (srcDur > config.minSegmentDuration + 2)
          ? random.nextDouble() * 2.0
          : 0.0;

      while (currentTime + config.minSegmentDuration <= srcDur) {
        double maxPossible = min(
          config.maxSegmentDuration.toDouble(),
          srcDur - currentTime,
        );
        if (maxPossible < config.minSegmentDuration) break;

        final deltaRange = maxPossible - config.minSegmentDuration;
        final segDur =
            config.minSegmentDuration + (random.nextDouble() * deltaRange);

        pool.add(
          SegmentRequest(
            sourcePath: src,
            startTime: currentTime,
            duration: segDur,
            hflip: isRetry
                ? random.nextDouble() < 0.7
                : random.nextDouble() < 0.3,
            hasAudio: videoHasAudio[src] ?? false,
          ),
        );
        currentTime += segDur;
      }
    }
    pool.shuffle(random);
    return pool;
  }

  /// Trả về số lượng encode task song song tối đa dựa trên hardware đang dùng.
  /// Thay thế static getter cứng nhắc trước đây.
  Future<int> resolveMaxConcurrentTasks() async {
    final gpu = await getGpuInfo();
    return gpu.maxConcurrentEncodes;
  }

  Future<String?> runSegmentCut({
    required String input,
    required double startSeconds,
    required double duration,
    required String output,
    required bool hflip,
    required bool hasAudio,
    String? processName,
    void Function(double)? onProgress,
    void Function(String)? onLogMsg,
  }) async {
    if (!await File(input).exists()) {
      onLogMsg?.call(
        '  ❌ [${processName ?? p.basename(input)}] Lỗi: Không tìm thấy file nguồn',
      );
      return null;
    }

    final probeResult = await probeSourceVideo(input);
    final colorInfo = probeResult.colorInfo;
    final hdr = isHdr(transfer: colorInfo.transfer, pixFmt: colorInfo.pixFmt);

    return runSegmentEncode(
      input: input,
      startSeconds: startSeconds,
      duration: duration,
      output: output,
      hflip: hflip,
      hasAudio: hasAudio,
      isHdr: hdr,
      colorInfo: colorInfo,
      processName: processName,
      onProgress: onProgress,
      onLogMsg: onLogMsg,
    );
  }

  Future<String?> runSegmentEncode({
    required String input,
    required double startSeconds,
    required double duration,
    required String output,
    required bool hflip,
    required bool hasAudio,
    required bool isHdr,
    required ({String transfer, String primaries, String pixFmt}) colorInfo,
    String? processName,
    void Function(double)? onProgress,
    void Function(String)? onLogMsg,
  }) async {
    final gpuInfo = await getGpuInfo();
    final isNvidia = gpuInfo.encoder == 'h264_nvenc';
    final hwScale = gpuInfo.scaleFilter ?? 'scale';

    String vfFilter;

    if (isNvidia && isHdr) {
      if (gpuInfo.hasZscale && gpuInfo.hasCudaFilters) {
        // NVIDIA HDR: download→tonemap→upload lại cho NVENC
        vfFilter =
            'hwdownload,format=p010le,'
            'zscale=t=linear:npl=100,'
            'format=gbrpf32le,'
            'zscale=p=bt709,'
            'tonemap=tonemap=hable:desat=0,'
            'zscale=t=bt709:m=bt709,'
            'format=nv12,'
            'hwupload_cuda,$hwScale=1080:1920';
        if (hflip) vfFilter += ',hflip_cuda';
      } else {
        String base = gpuInfo.hasCudaFilters
            ? '$hwScale=1080:1920'
            : 'scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920';
        if (hflip) base += gpuInfo.hasCudaFilters ? ',hflip_cuda' : ',hflip';

        if (gpuInfo.hasZscale) {
          final download = gpuInfo.outputFormat != null
              ? 'hwdownload,format=p010le,'
              : '';
          vfFilter =
              '${download}zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=yuv420p,$base';
        } else {
          final download = gpuInfo.outputFormat != null
              ? 'hwdownload,format=p010le,'
              : '';
          vfFilter = '${download}format=yuv420p,$base';
        }
      }
    } else if (isHdr) {
      // HDR fallback cho macOS và Windows non-NVIDIA
      String base =
          (gpuInfo.scaleFilter != null && gpuInfo.scaleFilter != 'scale')
          ? '$hwScale=1080:1920'
          : 'scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920';
      if (hflip) base += ',hflip';

      final download = gpuInfo.outputFormat != null
          ? 'hwdownload,format=p010le,'
          : '';
      if (gpuInfo.hasZscale) {
        vfFilter =
            '$download$base,'
            'zscale=t=linear:npl=100,'
            'format=gbrpf32le,'
            'zscale=p=bt709,'
            'tonemap=tonemap=hable:desat=0,'
            'zscale=t=bt709:m=bt709,'
            'format=yuv420p';
      } else {
        vfFilter = '$download$base,format=yuv420p';
      }
    } else if (isNvidia && gpuInfo.hasCudaFilters) {
      // NVIDIA SDR: giữ frame trên GPU, chỉ download để lấy format encoder cần
      final download = gpuInfo.outputFormat != null
          ? 'hwdownload,format=nv12,'
          : '';
      vfFilter = '$download$hwScale=1080:1920';
      if (hflip) vfFilter += ',hflip_cuda';
      vfFilter += ',format=nv12';
    } else {
      // Windows non-NVIDIA SDR (QSV, AMF) hoặc software fallback
      String base = (gpuInfo.scaleFilter != null)
          ? '$hwScale=1080:1920'
          : 'scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920';
      if (hflip) base += ',hflip';
      final download = gpuInfo.outputFormat != null
          ? 'hwdownload,format=nv12,'
          : '';
      vfFilter = '$download$base,format=yuv420p';
    }

    final afFilter = hasAudio ? 'aresample=44100' : 'anullsrc';

    final result = await runWithFilter(
      vfFilter,
      afFilter,
      gpuInfo,
      input: input,
      startSeconds: startSeconds,
      duration: duration,
      output: output,
      processName: processName,
      onProgress: onProgress,
      onLogMsg: onLogMsg,
    );

    if (result == null && !cancelled) {
      final fallbackGpuInfo = (
        encoder: 'libx264',
        hwaccel: null,
        scaleFilter: null,
        outputFormat: null,
        hasZscale: gpuInfo.hasZscale,
        hasCudaFilters: false,
        preferredPixFmt: 'yuv420p',
        maxConcurrentEncodes: gpuInfo.maxConcurrentEncodes,
      );
      onLogMsg?.call(
        '  ⚠️ [${processName ?? p.basename(input)}] Encode GPU thất bại, thử fallback CPU...',
      );

      final cpuScale =
          'scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920${hflip ? ",hflip" : ""}';
      String fallbackFilter;
      if (isHdr && gpuInfo.hasZscale) {
        fallbackFilter =
            '$cpuScale,zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709,format=yuv420p';
      } else {
        fallbackFilter = '$cpuScale,format=yuv420p';
      }

      return runWithFilter(
        fallbackFilter,
        afFilter,
        fallbackGpuInfo,
        input: input,
        startSeconds: startSeconds,
        duration: duration,
        output: output,
        processName: processName,
        onProgress: onProgress,
        onLogMsg: onLogMsg,
      );
    }

    if (result == null && isHdr && !cancelled) {
      onLogMsg?.call(
        '  ⚠️ [${processName ?? p.basename(input)}] Tonemapping thất bại, thử fallback SDR...',
      );
      final cpuScale =
          'scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920${hflip ? ",hflip" : ""}';
      final fallbackFilter = '$cpuScale,format=yuv420p';

      return runWithFilter(
        fallbackFilter,
        afFilter,
        gpuInfo,
        input: input,
        startSeconds: startSeconds,
        duration: duration,
        output: output,
        processName: processName,
        onProgress: onProgress,
        onLogMsg: onLogMsg,
      );
    }

    return result;
  }

  Future<String?> runWithFilter(
    String vf,
    String af,
    GpuInfo gpuInfo, {
    required String input,
    required double startSeconds,
    required double duration,
    required String output,
    String? processName,
    void Function(double)? onProgress,
    void Function(String)? onLogMsg,
  }) async {
    try {
      final List<String> args = ['-hide_banner', '-y'];

      // Khôi phục hwaccel cho macOS:
      // Giải mã bằng GPU (videotoolbox), sau đó do dùng CPU filter (scale, trim của -t)
      // nên FFmpeg tự động hwdownload xuống nv12. Điều này giúp tận dụng GPU decode
      // mà không làm vỡ các CPU filter ở bước sau.
      if (gpuInfo.hwaccel != null) {
        args.addAll(['-hwaccel', gpuInfo.hwaccel!]);
        if (gpuInfo.outputFormat != null) {
          args.addAll(['-hwaccel_output_format', gpuInfo.outputFormat!]);
        }
      }

      args.addAll([
        '-ss',
        startSeconds.toStringAsFixed(3),
        '-fflags',
        '+genpts+igndts',
        '-i',
        input,
      ]);

      if (af == 'anullsrc') {
        args.addAll(['-f', 'lavfi', '-i', 'anullsrc=r=44100:cl=stereo']);
      }

      args.addAll(['-t', duration.toStringAsFixed(3), '-vf', vf]);

      if (af == 'anullsrc') {
        args.addAll([
          '-map',
          '0:v:0',
          '-map',
          '1:a:0',
          '-c:a',
          'aac',
          '-shortest',
        ]);
      } else {
        args.addAll(['-af', af, '-c:a', 'aac']);
      }

      args.addAll([
        // Fix Bug 4: dùng preferredPixFmt phù hợp với từng encoder
        '-pix_fmt', gpuInfo.preferredPixFmt,
        '-colorspace', 'bt709',
        '-color_trc', 'bt709',
        '-color_primaries', 'bt709',
        '-c:v', gpuInfo.encoder,
      ]);

      if (gpuInfo.encoder == 'libx264') {
        args.addAll([
          '-preset',
          'ultrafast',
          '-b:v',
          '10M',
          '-maxrate',
          '12M',
          '-bufsize',
          '20M',
        ]);
      } else if (gpuInfo.encoder == 'h264_videotoolbox') {
        args.addAll(['-b:v', '10M', '-realtime', '1']);
      } else if (gpuInfo.encoder == 'h264_qsv') {
        args.addAll(['-b:v', '10M', '-preset', 'veryfast']);
      } else {
        args.addAll(['-b:v', '10M', '-maxrate', '12M', '-bufsize', '20M']);
      }

      args.addAll([
        '-movflags',
        '+faststart',
        '-avoid_negative_ts',
        'make_zero',
        '-map_metadata',
        '-1',
        output,
      ]);

      final process = await Process.start(BatchVideoGpuMixin.ffmpegBin, args);
      activeProcesses.add(process);

      final regex = RegExp(r'time=(\d{2}):(\d{2}):(\d{2}\.\d{2})');
      final stderrList = <String>[];

      process.stderr.listen((data) {
        final out = String.fromCharCodes(data);
        final lines = out.split('\n');
        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            stderrList.add(line);
            if (stderrList.length > 15) stderrList.removeAt(0);
          }
        }

        if (onProgress == null || cancelled) return;
        final match = regex.firstMatch(out);
        if (match != null) {
          final h = int.parse(match.group(1)!);
          final m = int.parse(match.group(2)!);
          final s = double.parse(match.group(3)!);
          final currentSeconds = h * 3600 + m * 60 + s;
          final percent = (currentSeconds / duration).clamp(0.0, 1.0);
          onProgress(percent);
        }
      });

      final exitCode = await process.exitCode;
      activeProcesses.remove(process);

      if (exitCode != 0 || !File(output).existsSync()) {
        final errorLog = stderrList.join('\n');
        if (errorLog.isNotEmpty && !cancelled) {
          final filterInfo = ' (Filters: vf=$vf)';
          onLogMsg?.call(
            '  ❌ [${processName ?? p.basename(input)}] FFmpeg lỗi (exit $exitCode):\n$errorLog$filterInfo',
          );
        }
        return null;
      }
      return output;
    } catch (e) {
      if (!cancelled)
        onLogMsg?.call(
          '  ❌ [${processName ?? p.basename(input)}] Exception: $e',
        );
      return null;
    }
  }
}
