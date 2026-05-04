import 'package:scraki/features/video_poster/data/services/batch_video/engines/common/ffmpeg_toolkit.dart';

/// Apple-specific implementation of [VideoToolkit] using VideoToolbox.
class AppleToolkit extends BaseFfmpegToolkit {
  @override
  String scale(int width, int height, {double? iwScale, String? expression}) {
    // Apple VideoToolbox often uses 'scale_vt' for hardware scaling, 
    // but standard 'scale' is safer as a base. 
    // Subclasses can override if scale_vt is confirmed available.
    if (expression != null) return 'scale=$expression';
    if (iwScale != null) return 'scale=iw*$iwScale:-1';
    return 'scale=$width:$height';
  }
}
