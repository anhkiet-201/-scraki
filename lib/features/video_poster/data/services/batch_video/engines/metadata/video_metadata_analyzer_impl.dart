import 'dart:io';
import 'package:injectable/injectable.dart';
import '../hardware/video_hardware_capability_resolver.dart';
import 'video_metadata_analyzer.dart';

@LazySingleton(as: VideoMetadataAnalyzer)
class VideoMetadataAnalyzerImpl implements VideoMetadataAnalyzer {
  final VideoHardwareCapabilityResolver _hardwareResolver;
  final Map<String, ProbeResult> _probeCache = {};

  VideoMetadataAnalyzerImpl(this._hardwareResolver);

  @override
  Future<ProbeResult> probeSourceVideo(String path) async {
    if (_probeCache.containsKey(path)) return _probeCache[path]!;

    try {
      final result = await Process.run(_hardwareResolver.ffprobeBin, [
        '-v', 'error',
        '-show_entries', 'format=duration:stream=codec_type,color_transfer,color_primaries,pix_fmt',
        '-of', 'default=noprint_wrappers=1:nokey=0',
        path,
      ]);

      final out = result.stdout as String;
      
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

      final res = (
        duration: durationSec.round(), 
        hasAudio: hasAudio, 
        colorInfo: (transfer: transfer, primaries: primaries, pixFmt: pixFmt)
      );
      _probeCache[path] = res;
      return res;
    } catch (_) {
      return (
        duration: 0, 
        hasAudio: false, 
        colorInfo: (transfer: 'unknown', primaries: 'unknown', pixFmt: 'unknown')
      );
    }
  }

  @override
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

  @override
  void clearCache() {
    _probeCache.clear();
  }
}
