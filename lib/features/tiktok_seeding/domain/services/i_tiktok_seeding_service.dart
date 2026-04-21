abstract class ITikTokSeedingService {
  /// Mở trang tìm kiếm TikTok trên thiết bị với một từ khóa hoặc link.
  /// Tự động nhận diện variant để dùng đúng Scheme Deep Link.
  Future<void> openSearch(String serial, String query);
}
