import 'package:scraki/features/video_poster/data/services/batch_video/models/batch_video_models.dart';
import '../../video_composition_engine.dart';

class NvidiaCompositionEngine implements VideoCompositionEngine {
  @override
  String buildCompositionFilter({
    required double zoomVal,
    required double randX,
    required double randY,
    required CompositionColorSettings colorSettings,
    required GpuInfo gpuInfo,
    required double pts,
  }) {
    final sb = StringBuffer();
    final zoomW = (1080 * zoomVal).round();
    final zoomH = (1920 * zoomVal).round();

    // Stage 1: HW Scale & Crop
    if (gpuInfo.hasCudaFilters) {
      sb.write('[0:v]scale_cuda=$zoomW:$zoomH,crop=1080:1920:(iw-1080)*$randX:(ih-1920)*$randY,hwdownload,format=nv12');
    } else {
      sb.write('[0:v]scale=$zoomW:$zoomH:force_original_aspect_ratio=increase,crop=1080:1920:(iw-1080)*$randX:(ih-1920)*$randY,format=nv12');
    }

    // Stage 2: Color Correction (CPU - since complex filters usually run on CPU)
    if (colorSettings.colorChannelMixer != null) {
      sb.write(',colorchannelmixer=${colorSettings.colorChannelMixer}');
    }
    if (colorSettings.curves != null) {
      sb.write(',curves=${colorSettings.curves}');
    }
    if (colorSettings.colorBalance != null) {
      sb.write(',colorbalance=${colorSettings.colorBalance}');
    }

    final b = colorSettings.brightness.toStringAsFixed(4);
    final c = colorSettings.contrast.toStringAsFixed(4);
    if (colorSettings.gamma != null) {
      sb.write(',eq=brightness=$b:contrast=$c:gamma=${colorSettings.gamma!.toStringAsFixed(3)}');
    } else {
      final gR = colorSettings.gammaR?.toStringAsFixed(3) ?? '1.0';
      final gG = colorSettings.gammaG?.toStringAsFixed(3) ?? '1.0';
      final gB = colorSettings.gammaB?.toStringAsFixed(3) ?? '1.0';
      sb.write(',eq=brightness=$b:contrast=$c:gamma_r=$gR:gamma_g=$gG:gamma_b=$gB');
    }

    sb.write(',hue=h=${colorSettings.hueShift.toStringAsFixed(2)}:s=${colorSettings.satFactor.toStringAsFixed(4)}');
    sb.write(',vignette=${colorSettings.vignetteAngle.toStringAsFixed(4)}');

    // Stage 3: Final Format & Time
    sb.write(',format=nv12,trim=start=0,setpts=${pts.toStringAsFixed(6)}*N/30/TB');

    return sb.toString();
  }

  @override
  List<String> getCompositionEncoderArgs(
    GpuInfo gpuInfo, {
    String? bitrate,
    String? maxRate,
    String? bufSize,
    int? gop,
  }) {
    return [
      '-c:v', 'h264_nvenc',
      '-preset', 'p1',
      '-tune', 'hq',
      '-rc', 'vbr',
      '-b:v', bitrate ?? '12M',
      '-maxrate', maxRate ?? '16M',
      '-bufsize', bufSize ?? '25M',
      if (gop != null) ...['-g', gop.toString()],
    ];
  }

  @override
  String getPreferredPixFmt(GpuInfo gpuInfo) {
    return 'nv12';
  }
}
