# Poster Design & Implementation Guide

Tài liệu này mô tả chi tiết về kiến trúc hệ thống, ý tưởng thiết kế và danh sách các mẫu Poster tuyển dụng trong ứng dụng SCRAKI.

## 1. Kiến Trúc & Cách Triển Khai (Implementation)

Hệ thống Poster được xây dựng dựa trên các nguyên tắc Flexible, Scalable và Editable.

### 1.1. Core Concepts

- **Template Widget Pattern**: Mọi mẫu Poster đều kế thừa từ class trừu tượng base `PosterTemplate`.

  - `PosterTemplate` cung cấp các phương thức tiện ích (`wrapEditable`) và quản lý state chung.
  - Mỗi subclass (ví dụ `ModernPoster`, `VintagePoster`) chỉ tập trung vào việc render UI (`buildPoster`).

- **Data-Driven UI**: Nội dung Poster được tách biệt hoàn toàn khỏi giao diện thông qua `PosterData`.

  - `PosterData`: Chứa thông tin tuyển dụng (Job Title, Salary, Location, Requirements, Benefits...).
  - Dữ liệu này được inject vào Template khi khởi tạo.

- **Real-time Customization (MobX)**:

  - Sử dụng `PosterCustomizationStore` để quản lý các thay đổi text người dùng nhập vào.
  - Widget `wrapEditable`: Bọc các thành phần text cho phép người dùng chạm vào để sửa. Mỗi vùng text có một `id` duy nhất (ví dụ: `req_0`, `ben_1`, `jobTitle`).
  - Khi render, ưu tiên hiển thị text từ Store (nếu có override), nếu không sẽ dùng data gốc.

- **Responsive Scaling**:
  - Hệ thống tính toán tỉ lệ `scale` dựa trên kích thước màn hình hiển thị so với kích thước chuẩn của thiết kế.
  - Tất cả kích thước (fontSize, padding, margin, width, height) đều nhân với `scale` để đảm bảo Poster hiển thị giống hệt nhau trên mọi thiết bị và khi xuất file ảnh chất lượng cao.

### 1.2. Kỹ Thuật Layout

- **Safe Overflow**: Các danh sách dài (Requirements, Benefits) luôn được bọc trong `Expanded` + `SingleChildScrollView` (hoặc cơ chế tương đương) để tránh lỗi tràn màn hình (Red Screen) khi nội dung quá dài.
- **Side-by-Side Lists**: Các mục "Yêu cầu" và "Quyền lợi" được bố trí song song (Row > Expanded > Column) trong các mẫu hiện đại để tối ưu không gian dọc.
- **Glassmorphism**: Áp dụng hiệu ứng kính mờ (`BackdropFilter` + `Blur`) cho các mẫu Creative để tạo chiều sâu và vẻ hiện đại.

---

## 2. Danh Sách Các Mẫu Poster (Poster Catalog)

Hiện tại hệ thống hỗ trợ 20 mẫu Poster đa dạng phong cách:

| Tên Template         | Ý Tưởng Thiết Kế (Design Concept)                                                          | Phù Hợp Cho                             |
| :------------------- | :----------------------------------------------------------------------------------------- | :-------------------------------------- |
| **1. Modern**        | Hiện đại, sạch sẽ, bố cục cân đối. Sử dụng màu xanh/trắng chủ đạo.                         | Doanh nghiệp công nghệ, văn phòng.      |
| **2. Minimalist**    | Tối giản, nhiều khoảng trắng (negative space), tập trung typography.                       | Studio thiết kế, thời trang, lifestyle. |
| **3. Bold**          | Font chữ cực lớn, nét đậm, độ tương phản cao. Gây ấn tượng mạnh thị giác.                  | Marketing, Sales, sự kiện sôi động.     |
| **4. Corporate**     | Chuyên nghiệp, nghiêm túc, bố cục dạng lưới (grid) chuẩn mực.                              | Tập đoàn tài chính, luật, hành chính.   |
| **5. Creative**      | Phá cách, Glassmorphism (kính mờ), gradient màu pastel rực rỡ, hình khối abstract.         | Agency quảng cáo, Startups, Nghệ thuật. |
| **6. Elegant**       | Sang trọng, dùng font có chân (Serif), màu vàng kim/đen/trắng.                             | Khách sạn, trang sức, dịch vụ cao cấp.  |
| **7. High Contrast** | Tương phản gắt (Đen/Vàng), style đường phố hoặc cảnh báo chú ý.                            | Xây dựng, vận tải, tuyển dụng gấp.      |
| **8. Typography**    | Dùng chữ làm yếu tố đồ họa chính. Bố cục text dày đặc nhưng nghệ thuật.                    | Báo chí, biên tập, copywriter.          |
| **9. Nature**        | Tông màu xanh lá, họa tiết lá cây, cảm giác tươi mát, thân thiện.                          | Spa, thực phẩm sạch, môi trường.        |
| **10. Urban**        | Phong cách đường phố, bụi bặm, tông màu tối, graffity texture.                             | Thời trang Streetwear, Skateboard, Bar. |
| **11. Luxury**       | Đẳng cấp, nền tối, chi tiết mạ vàng, họa tiết tinh xảo.                                    | Bất động sản cao cấp, xe hơi, CEO.      |
| **12. Geometric**    | Sử dụng các hình khối hình học (tam giác, tròn, vuông) phối màu color-block.               | Kiến trúc, IT, Toán học.                |
| **13. Vintage**      | Giả lập giấy cũ, texture nhiễu hạt, font cổ điển. Hoài niệm.                               | Quán Cafe, đồ handmade, tiệm sách cũ.   |
| **14. Neon**         | Hiệu ứng đèn Neon phát sáng trên nền tối (Cyberpunk).                                      | Nightclub, Game Center, công nghệ.      |
| **15. Abstract**     | Hình khối trừu tượng mềm mại, màu sắc loang (gradient mesh).                               | Mỹ phẩm, làm đẹp, sáng tạo nội dung.    |
| **16. Professional** | Tương tự Corporate nhưng mềm mại hơn, tông xanh Indigo tin cậy.                            | Giáo dục, y tế, tư vấn.                 |
| **17. Tech**         | Mạch điện tử, lưới số (digital grid), tông xanh dương neon/đen.                            | Lập trình viên, kỹ sư phần mềm.         |
| **18. Swiss**        | Phong cách Swiss Design (International Typographic Style). Grid chặt chẽ, font không chân. | Thiết kế đồ họa, kiến trúc sư.          |
| **19. Retro**        | Phong cách thập niên 80-90, màu sắc rực rỡ (Pop Art).                                      | Giải trí, truyền thông, sự kiện trẻ.    |
| **20. Playful**      | Vui nhộn, nhiều màu sắc, hình minh họa dễ thương.                                          | Trường mầm non, khu vui chơi, FMCG.     |

## 3. Quy Tắc Chỉnh Sửa & Bảo Trì

- **Thêm Template mới**:
  1.  Tạo file mới trong `lib/features/poster/presentation/widgets/`.
  2.  Kế thừa `PosterTemplate`.
  3.  Implement `templateId` (duy nhất) và `buildPoster`.
  4.  Đăng ký trong `PosterTemplateType` enum và `PosterPanel`.
- **Chỉnh sửa**:
  - Sử dụng `wrapEditable` cho mọi text cứng.
  - Luôn kiểm tra overflow với `SingleChildScrollView`.
  - Tuân thủ quy tắc đặt ID: `req_{index}`, `ben_{index}` cho các list items.

---
