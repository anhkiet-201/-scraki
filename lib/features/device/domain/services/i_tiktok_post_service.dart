enum TikTokVariant { global, asia, lite }

enum TikTokLanguage { en, vi }

abstract class ITikTokPostService {
  /// Nhận diện phiên bản TikTok đang cài đặt trên thiết bị.
  Future<TikTokVariant?> detectInstalledVariant(String serial);

  /// Mở màn hình đăng video của TikTok thông qua Share Intent.
  Future<void> openTikTokCreate(String serial, String localVideoPath);

  /// (Đã xóa autoPostVideo theo yêu cầu lean)
}
