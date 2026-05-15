
abstract interface class VideoToolkit {
  /// Thao tác phóng to/thu nhỏ. Hỗ trợ kích thước cố định hoặc theo tỉ lệ (iwScale) hoặc expression tùy chỉnh.
  String scale(int width, int height, {double? iwScale, String? expression});

  /// Thao tác xoay
  String rotate(double angle, {int? ow, int? oh});

  /// Hiệu ứng mờ dần (Fade)
  String fade({required String type, required double start, required double duration});

  /// Vẽ khung viền (Drawbox)
  String drawbox({required String c, required int t});

  /// Helper chuyển đổi màu sang Hex string (FFmpeg format)
  String colorToHex(dynamic color);

  /// Thao tác cắt khung hình. x và y có thể là int hoặc expression (mặc định căn giữa).
  String crop(int width, int height, {dynamic x, dynamic y});

  /// Thao tác chèn viền (Padding) để vừa khung hình
  String pad(int width, int height, {dynamic x, dynamic y, String color = 'black'});

  /// Thao tác lật ngang
  String hflip();

  /// Thao tác điều chỉnh tốc độ
  String adjustSpeed(double pts);

  /// Điều chỉnh Brightness, Contrast, Saturation, Gamma
  String eq({double brightness = 0.0, double contrast = 1.0, double saturation = 1.0, double gamma = 1.0});

  /// Điều chỉnh Hue, Saturation
  String hue({double? hueShift, double? saturation});

  /// Hiệu ứng tối góc (Vignette)
  String vignette(double angle);

  /// Áp dụng LUT 3D từ file
  String lut3d(String lutFilePath);

  /// Chồng lớp (Overlay) - Tự động chọn filter phù hợp phần cứng
  String overlay({String? x, String? y, String? enable, bool shortest = true});
}
