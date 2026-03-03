# AkiRemote CLI - Android Control Tool via ADB

`aki_remote` là một công cụ dòng lệnh (CLI) mạnh mẽ chạy trực tiếp trên thiết bị Android, cho phép điều khiển giao diện người dùng (UI) thông qua giao thức ADB. Công cụ này sử dụng trực tiếp Android Native Accessibility APIs (`UiAutomation`) để đảm bảo tốc độ phản hồi nhanh và khả năng tương tác chính xác mà không cần cài đặt các framework test phức tạp.

## 🚀 Tính năng nổi bật

- **Tương tác UI thông minh**: Hỗ trợ Click, Type, Get text, Swipe và Dump cấu trúc màn hình.
- **Coordinate Fallback**: Tự động chuyển sang nhấn theo tọa độ (input tap) nếu lệnh Click hệ thống (`ACTION_CLICK`) không phản hồi trên phần tử.
- **Xử lý Tiếng Việt hoàn hảo**: Hỗ trợ nhập liệu và tìm kiếm text Tiếng Việt có dấu (Unicode NFC).
- **So khớp linh hoạt**: Hỗ trợ Selector với khớp chính xác (`id`, `text`, `class`, `desc`) và khớp chuỗi con (`text-contains`, `desc-contains`, `id-contains`) kết hợp với toán tử `&&`.
- **Auto-join Arguments**: Tự động nối các tham số có khoảng trắng bị shell chia nhỏ (ví dụ: `text:Samsung account`).
- **Lệnh Debug `find`**: Cho phép tra cứu chi tiết thuộc tính của Node để tinh chỉnh selector.

## 🏗️ Kiến trúc & Công nghệ

Dự án được xây dựng dựa trên các nguyên tắc **Clean Architecture** và **SOLID**:

- **Ngôn ngữ**: Thuần Java (để loại bỏ phụ thuộc vào Kotlin runtime, tránh lỗi `exit code 137`).
- **Core Library**: Sử dụng `android.app.UiAutomation` và `android.view.accessibility.AccessibilityNodeInfo`.
- **DEX Execution**: Mã nguồn được biên dịch thành file DEX và chạy thông qua `app_process`.

## 🛠️ Cài đặt & Triển khai

### Yêu cầu hệ thống

- Android SDK (cần `d8` để build).
- Thiết bị chạy Android 7.0 (API 24) trở lên.
- Đã kết nối ADB.

### Các bước triển khai

1. Kết nối thiết bị:
   ```bash
   adb connect <device_ip>
   ```
2. Build dự án thành file JAR (DEX):
   ```bash
   chmod +x build.sh
   ./build.sh
   ```
3. Chạy script push để tải công cụ lên `/data/local/tmp/`:
   ```bash
   chmod +x ./aki-remote-cli/push.sh
   ./aki-remote-cli/push.sh
   ```

## 🔍 Chi tiết về Selector

Công cụ hỗ trợ các loại selector sau để xác định phần tử:

| Selector                | Kiểu khớp      | Trường tìm kiếm |
| ----------------------- | -------------- | --------------- |
| `id:<value>`            | Chính xác      | resource-id     |
| `id-contains:<value>`   | Chứa chuỗi con | resource-id     |
| `text:<value>`          | Chính xác      | text            |
| `text-contains:<value>` | Chứa chuỗi con | text            |
| `desc:<value>`          | Chính xác      | content-desc    |
| `desc-contains:<value>` | Chứa chuỗi con | content-desc    |
| `class:<value>`         | Chính xác      | class           |
| _(không prefix)_        | Chứa chuỗi con | text hoặc desc  |

### Kết hợp Selector (Toán tử `&&`)

Bạn có thể gộp nhiều điều kiện để tìm chính xác phần tử trong các cấu trúc lồng nhau phức tạp:

```bash
# Tìm TextView có id cụ thể VÀ nội dung là "Samsung account"
adb shell /data/local/tmp/aki_remote click "id:android:id/title && text:Samsung account"

# Tìm Button có class là Button VÀ text chứa "Hẹn"
adb shell /data/local/tmp/aki_remote click "class:android.widget.Button && text-contains:Hẹn"

# Tìm element có resource-id chứa "username" và lấy text
adb shell /data/local/tmp/aki_remote get "id-contains:username"
```

## 📖 Hướng dẫn sử dụng

### Tóm tắt lệnh

| Lệnh      | Cú pháp                                          | Mô tả                                 |
| --------- | ------------------------------------------------ | ------------------------------------- |
| `click`   | `click <selector>`                               | Nhấn vào phần tử                      |
| `type`    | `type <text>` hoặc `type <selector> \|\| <text>` | Nhập liệu (có hoặc không có selector) |
| `get`     | `get <selector>`                                 | Lấy text của phần tử                  |
| `find`    | `find <selector>`                                | Tra cứu thuộc tính node (debug)       |
| `dump`    | `dump`                                           | Xuất cấu trúc UI dạng XML             |
| `swipe`   | `swipe <direction> <ratio> [duration]`           | Vuốt màn hình theo hướng              |
| `size`    | `size`                                           | Lấy kích thước màn hình               |
| `home`    | `home`                                           | Nhấn nút Home                         |
| `back`    | `back`                                           | Nhấn nút Back                         |
| `recents` | `recents`                                        | Mở màn hình Recent Apps               |

---

### 1. Click (Nhấn vào phần tử)

Tự động tìm phần tử theo selector và nhấn. Hỗ trợ khoảng trắng và toán tử gộp.

```bash
adb shell /data/local/tmp/aki_remote click "text:Kết nối"
adb shell /data/local/tmp/aki_remote click "class:android.widget.TextView && text:Samsung account"
```

### 2. Type (Nhập liệu)

Nếu không truyền selector, tự động nhập vào element đang **focus**.

```bash
# Nhập vào element đang focus
adb shell /data/local/tmp/aki_remote type "Xin chào Việt Nam"

# Nhập vào element cụ thể (selector || text)
adb shell /data/local/tmp/aki_remote type "id:input_id || Xin chào Việt Nam"
```

### 3. Get (Lấy text của phần tử)

Tìm phần tử theo selector và in ra nội dung `text` của nó.

```bash
adb shell /data/local/tmp/aki_remote get "id:com.example:id/username"
adb shell /data/local/tmp/aki_remote get "text-contains:Nguyễn"
```

### 4. Find (Tra cứu thông tin Node)

Dùng để debug — in ra đầy đủ các thuộc tính: text, resource-id, class, content-desc, bounds, clickable.

```bash
adb shell /data/local/tmp/aki_remote find "text:Samsung"
adb shell /data/local/tmp/aki_remote find "text-contains:Hẹn"
```

### 5. Dump (Xuất cấu trúc UI)

Xuất toàn bộ cây thư mục UI ra định dạng XML.

```bash
adb shell /data/local/tmp/aki_remote dump
```

### 6. Swipe (Vuốt màn hình)

**Theo hướng** (khuyến nghị):

```bash
# swipe <up|down|left|right> <ratio 0.0-1.0> [duration_ms]
# ratio: tỉ lệ khoảng cách vuốt so với kích thước màn hình, duration mặc định 1000ms
adb shell /data/local/tmp/aki_remote swipe up 0.6
adb shell /data/local/tmp/aki_remote swipe down 0.5 800
adb shell /data/local/tmp/aki_remote swipe left 0.7 500
```

**Theo tọa độ**:

```bash
adb shell /data/local/tmp/aki_remote swipe <x1> <y1> <x2> <y2> [duration_ms]
```

### 7. Size (Lấy kích thước màn hình)

```bash
adb shell /data/local/tmp/aki_remote size
# Output: 1080x2220
```

### 8. Điều hướng hệ thống (Home, Back, Recents)

```bash
adb shell /data/local/tmp/aki_remote home
adb shell /data/local/tmp/aki_remote back
adb shell /data/local/tmp/aki_remote recents
```

Trả về `OK` nếu thực hiện thành công.

## ⚠️ Lưu ý quan trọng

- **Case-sensitive**: Công cụ phân biệt hoa thường khi so khớp text chính xác.
- **Permissions**: Cần quyền `shell` (mặc định qua ADB) để truy cập `UiAutomation`.
- **Trạng thái màn hình**: Màn hình phải đang bật và không ở trạng thái khóa để `UiAutomation` hoạt động ổn định.

---

_Phát triển bởi AkiRemote Team._
