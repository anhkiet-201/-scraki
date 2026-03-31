enum TikTokVariant { global, asia, lite }

enum TikTokLanguage { en, vi }

abstract class ITikTokPostService {
  /// Nhận diện phiên bản TikTok đang cài đặt trên thiết bị.
  Future<TikTokVariant?> detectInstalledVariant(String serial);

  /// Mở màn hình đăng video của TikTok thông qua Share Intent.
  Future<void> openTikTokCreate(String serial, String localVideoPath);

  /// Mở màn hình đăng nhiều ảnh của TikTok thông qua Share Intent (SEND_MULTIPLE).
  /// [folderPath] là đường dẫn thư mục (ví dụ: /.../Set_1) sẽ được push lên thiết bị.
  Future<void> openTikTokPostImages(String serial, String folderPath);
}
