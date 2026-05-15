import 'package:scraki/features/video_poster/data/services/batch_video/engines/common/ffmpeg_toolkit.dart';

/// NVIDIA-specific implementation of [VideoToolkit] using CUDA-accelerated filters.
/// 
/// This toolkit prioritizes `_cuda` variants of FFmpeg filters (e.g., `scale_cuda`) 
/// to ensure processing happens entirely on the GPU.
class NvidiaToolkit extends BaseFfmpegToolkit {

  /// The name of the scale filter used by NVIDIA (CUDA).
  String get scaleFilterName => 'scale';

  @override
  String scale(int width, int height, {double? iwScale, String? expression}) {
    if (expression != null) return '$scaleFilterName=$expression';
    if (iwScale != null) return '$scaleFilterName=iw*$iwScale:-1';
    return '$scaleFilterName=$width:$height';
  }

  @override
  String crop(int width, int height, {dynamic x, dynamic y}) {
    final xStr = x?.toString() ?? '(in_w-$width)/2';
    final yStr = y?.toString() ?? '(in_h-$height)/2';
    return 'crop=$width:$height:$xStr:$yStr';
  }

  @override
  String pad(int width, int height, {dynamic x, dynamic y, String color = 'black'}) {
    final xStr = x?.toString() ?? 'trunc((ow-iw)/4)*2';
    final yStr = y?.toString() ?? 'trunc((oh-ih)/4)*2';
    return 'pad=$width:$height:$xStr:$yStr:color=$color';
  }

  @override
  String hflip() {
    return 'hflip';
  }

  @override
  String adjustSpeed(double pts) => 'setpts=${pts.toStringAsFixed(6)}*PTS';

  @override
  String eq({
    double brightness = 0.0,
    double contrast = 1.0,
    double saturation = 1.0,
    double gamma = 1.0,
  }) {
    return 'eq=brightness=$brightness:contrast=$contrast:saturation=$saturation:gamma=$gamma';
  }

  @override
  String hue({double? hueShift, double? saturation}) {
    final List<String> parts = [];
    if (hueShift != null) parts.add('h=$hueShift');
    if (saturation != null) parts.add('s=$saturation');
    return 'hue=${parts.join(':')}';
  }

  @override
  String vignette(double angle) => 'vignette=angle=$angle';

  @override
  String lut3d(String lutFilePath) {
    final escaped = lutFilePath.replaceAll(r'\', '/').replaceAll(':', r'\:');
    return "lut3d=file='$escaped'";
  }

  @override
  String overlay({String? x, String? y, String? enable, bool shortest = true}) {
    final List<String> parts = [];
    if (x != null) parts.add("x='$x'");
    if (y != null) parts.add("y='$y'");
    if (enable != null) parts.add('enable=\'$enable\'');
    if (shortest) parts.add('shortest=1');
    return 'overlay=${parts.join(':')}';
  }
}
