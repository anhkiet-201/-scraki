import 'dart:io';
import 'package:scraki/features/video_poster/data/services/batch_video/mixins/batch_video_gpu_mixin.dart';

mixin BatchVideoProbeMixin on BatchVideoGpuMixin {
  final Map<String, ({String transfer, String primaries, String pixFmt})> colorInfoCache = {};

  Future<({int duration, bool hasAudio, ({String transfer, String primaries, String pixFmt}) colorInfo})>
  probeSourceVideo(String path) async {
    try {
      final result = await Process.run(BatchVideoGpuMixin.ffprobeBin, [
        '-show_entries',
        'format=duration:stream=codec_type,color_transfer,color_primaries,pix_fmt,duration',
        '-of', 'default=noprint_wrappers=1:nokey=0',
        path,
      ]);
      final out = result.stdout as String;
      final err = result.stderr as String;

      double durationSec = 0;
      bool hasAudio = false;
      String transfer = 'unknown';
      String primaries = 'unknown';
      String pixFmt = 'unknown';

      for (final line in out.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('duration=')) {
          final val = double.tryParse(trimmed.split('=').last.trim());
          if (val != null && val > durationSec) durationSec = val;
        } else if (trimmed.startsWith('codec_type=audio')) {
          hasAudio = true;
        } else if (trimmed.startsWith('color_transfer=')) {
          final val = trimmed.split('=').last.trim();
          if (val != 'unknown') transfer = val;
        } else if (trimmed.startsWith('color_primaries=')) {
          final val = trimmed.split('=').last.trim();
          if (val != 'unknown') primaries = val;
        } else if (trimmed.startsWith('pix_fmt=')) {
          final val = trimmed.split('=').last.trim();
          if (val != 'unknown' && pixFmt == 'unknown') pixFmt = val;
        }
      }

      if (durationSec == 0) {
        final durationRegex = RegExp(r'Duration:\s*(\d+):(\d+):(\d+\.\d+)');
        final match = durationRegex.firstMatch(err);
        if (match != null) {
          final h = int.parse(match.group(1)!);
          final m = int.parse(match.group(2)!);
          final s = double.tryParse(match.group(3)!) ?? 0;
          durationSec = (h * 3600) + (m * 60) + s;
        }
      }

      final info = (
        duration: durationSec.round(),
        hasAudio: hasAudio,
        colorInfo: (transfer: transfer, primaries: primaries, pixFmt: pixFmt),
      );
      
      colorInfoCache[path] = info.colorInfo;
      return info;
    } catch (_) {
      return (
        duration: 0,
        hasAudio: false,
        colorInfo: (transfer: '', primaries: '', pixFmt: ''),
      );
    }
  }

  bool isHdr({required String transfer, required String pixFmt}) {
    const hdrTransfers = {'smpte2084', 'arib-std-b67', 'smpte428'};
    final hdrTransfer = hdrTransfers.contains(transfer);
    final hdrPixFmt =
        pixFmt.contains('p10') ||
        pixFmt.contains('p12') ||
        pixFmt.contains('10le') ||
        pixFmt.contains('10be');
    return hdrTransfer || hdrPixFmt;
  }

  void clearProbeCache() {
    colorInfoCache.clear();
  }
}
