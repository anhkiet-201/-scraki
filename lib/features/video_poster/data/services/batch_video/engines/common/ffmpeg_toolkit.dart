import 'package:scraki/features/video_poster/data/services/batch_video/core/toolkit/video_toolkit.dart';

/// Base implementation of [VideoToolkit] using standard FFmpeg filters.
///
/// This class generates filter strings compatible with CPU-based rendering
/// or as a fallback for hardware-accelerated engines.
class BaseFfmpegToolkit implements VideoToolkit {
  /// Generates a 'rotate' filter string.
  /// Defaults to a black background with full transparency for unused areas.
  @override
  String rotate(double angle, {int? ow, int? oh}) {
    String res = 'rotate=$angle*PI/180:c=black@0';
    if (ow != null) res += ':ow=$ow';
    if (oh != null) res += ':oh=$oh';
    return res;
  }

  /// Generates a 'fade' filter string for video transitions.
  @override
  String fade({
    required String type,
    required double start,
    required double duration,
  }) {
    return 'fade=t=$type:st=$start:d=$duration:alpha=1';
  }

  /// Generates a 'drawbox' filter string, often used for borders.
  @override
  String drawbox({required String c, required int t}) {
    return 'drawbox=c=$c:t=$t';
  }

  /// Converts various color inputs to FFmpeg-compatible hex strings (0xRRGGBB).
  ///
  /// Supports raw strings or Flutter-like Color objects (via dynamic toARGB32).
  @override
  String colorToHex(dynamic color) {
    if (color is String) return color;
    try {
      final int argb = (color as dynamic).toARGB32() as int;
      final String hex = argb.toRadixString(16).padLeft(8, '0');
      return '0x${hex.substring(2)}';
    } catch (_) {
      return 'white';
    }
  }

  /// Adjusts video playback speed using the 'setpts' filter.
  @override
  String adjustSpeed(double pts) => 'setpts=${pts.toStringAsFixed(6)}*PTS';

  /// Generates a 'crop' filter string.
  @override
  String crop(int width, int height, {dynamic x, dynamic y}) {
    final xStr = x?.toString() ?? '(in_w-$width)/2';
    final yStr = y?.toString() ?? '(in_h-$height)/2';
    return 'crop=$width:$height:$xStr:$yStr';
  }

  /// Generates a 'pad' filter string.
  @override
  String pad(int width, int height, {dynamic x, dynamic y, String color = 'black'}) {
    final xStr = x?.toString() ?? 'trunc((ow-iw)/4)*2';
    final yStr = y?.toString() ?? 'trunc((oh-ih)/4)*2';
    return 'pad=$width:$height:$xStr:$yStr:color=$color';
  }

  /// Adjusts visual properties using the 'eq' (equalizer) filter.
  @override
  String eq({
    double brightness = 0.0,
    double contrast = 1.0,
    double saturation = 1.0,
    double gamma = 1.0,
  }) {
    return 'eq=brightness=$brightness:contrast=$contrast:saturation=$saturation:gamma=$gamma';
  }

  /// Flips the video horizontally.
  @override
  String hflip() => 'hflip';

  /// Adjusts hue and saturation.
  @override
  String hue({double? hueShift, double? saturation}) {
    final List<String> parts = [];
    if (hueShift != null) parts.add('h=$hueShift');
    if (saturation != null) parts.add('s=$saturation');
    return 'hue=${parts.join(':')}';
  }

  /// Applies a 3D Look-Up Table (LUT) for color grading.
  @override
  String lut3d(String lutFilePath) {
    final escaped = lutFilePath.replaceAll(r'\', '/').replaceAll(':', r'\:');
    return "lut3d=file='$escaped'";
  }

  /// Overlays one stream on top of another.
  @override
  String overlay({String? x, String? y, String? enable, bool shortest = true}) {
    final List<String> parts = [];
    if (x != null) parts.add("x='$x'");
    if (y != null) parts.add("y='$y'");
    if (enable != null) parts.add('enable=\'$enable\'');
    if (shortest) parts.add('shortest=1');
    return 'overlay=${parts.join(':')}';
  }

  /// Scales the video to the specified dimensions.
  @override
  String scale(int width, int height, {double? iwScale, String? expression}) {
    if (expression != null) return 'scale=$expression';
    if (iwScale != null) return 'scale=iw*$iwScale:-1';
    return 'scale=$width:$height';
  }

  /// Applies a vignette effect (darkened corners).
  @override
  String vignette(double angle) => 'vignette=angle=$angle';
}
