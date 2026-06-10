enum FacebookPostTarget { feed, group, reels }

abstract class IFacebookPostService {
  /// Kiểm tra xem ứng dụng Facebook (com.facebook.katana) có được cài đặt trên thiết bị hay không.
  Future<bool> isFacebookInstalled(String serial);

  /// Mở màn hình tạo bài viết/tin với Video thông qua Share Intent trên Facebook.
  Future<void> openFacebookCreate(
    String serial,
    String localVideoPath, {
    required FacebookPostTarget target,
  });

  /// Mở màn hình đăng nhiều ảnh của Facebook thông qua Share Intent (SEND_MULTIPLE).
  /// [folderPath] là đường dẫn thư mục sẽ được push lên thiết bị.
  Future<void> openFacebookPostImages(String serial, String folderPath);
}

