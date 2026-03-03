import 'aki_selector.dart';

export 'aki_selector.dart';

/// Hướng swipe cho lệnh `swipe`.
enum SwipeDirection { up, down, left, right }

/// Contract cho service tương tác với CLI `aki_remote` trên Android qua ADB.
///
/// Trước khi gọi bất kỳ lệnh nào, cần đảm bảo binary đã được push lên device
/// bằng cách gọi [ensureServerPushed].
abstract class IAkiRemoteService {
  /// Push binary `aki_remote.jar` và shell wrapper lên `/data/local/tmp/`.
  ///
  /// Có cache nội bộ — chỉ push lại nếu device chưa từng được setup trong
  /// session hiện tại. An toàn để gọi nhiều lần.
  Future<void> ensureServerPushed(String serial);

  /// Nhấn vào phần tử UI được xác định bởi [selector].
  ///
  /// ```dart
  /// await service.click(serial, AkiSelector.text('Kết nối'));
  /// await service.click(serial,
  ///   AkiSelector.className('android.widget.Button') & AkiSelector.textContains('Hẹn'));
  /// ```
  Future<void> click(String serial, AkiSelector selector);

  /// Nhập [text] vào phần tử UI.
  ///
  /// Nếu [selector] không được truyền, text sẽ được nhập vào element đang focus.
  Future<void> type(String serial, String text, {AkiSelector? selector});

  /// Lấy nội dung `text` của phần tử UI được xác định bởi [selector].
  ///
  /// Trả về `null` nếu phần tử không có text hoặc không tìm thấy.
  Future<String?> get(String serial, AkiSelector selector);

  /// Lấy toàn bộ attributes của node UI để debug (text, resource-id, class,
  /// content-desc, bounds, clickable).
  Future<String> find(String serial, AkiSelector selector);

  /// Xuất toàn bộ cây UI ra định dạng XML.
  Future<String> dump(String serial);

  /// Vuốt màn hình theo [direction].
  ///
  /// [ratio] — tỉ lệ khoảng cách vuốt so với kích thước màn hình (0.0 – 1.0).
  /// [durationMs] — thời gian thực hiện vuốt (mặc định 1000ms).
  Future<void> swipe(
    String serial,
    SwipeDirection direction,
    double ratio, {
    int? durationMs,
  });

  /// Vuốt màn hình theo tọa độ tuyệt đối.
  Future<void> swipeByCoords(
    String serial,
    int x1,
    int y1,
    int x2,
    int y2, {
    int? durationMs,
  });

  /// Lấy kích thước màn hình device.
  ///
  /// Trả về record `({int width, int height})` — ví dụ: `(width: 1080, height: 2220)`.
  Future<({int width, int height})> getScreenSize(String serial);

  /// Nhấn nút Home.
  Future<void> home(String serial);

  /// Nhấn nút Back.
  Future<void> back(String serial);

  /// Mở màn hình Recent Apps.
  Future<void> recents(String serial);
}
