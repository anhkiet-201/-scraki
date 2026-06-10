abstract class IDeviceTaskService {
  /// Thực thi tác vụ upload file (push, install APK, OBB, TikTok)
  /// [serial] - Device serial number
  /// [paths] - Danh sách đường dẫn file cần upload
  /// [fileName] - Tên file gốc (dùng để kiểm tra loại file nếu cần)
  Future<void> executeFileUploadTask(String serial, List<String> paths);

  /// Hủy tác vụ đang chạy trên thiết bị (ví dụ: đang cài đặt)
  void cancelTask(String serial);
}
