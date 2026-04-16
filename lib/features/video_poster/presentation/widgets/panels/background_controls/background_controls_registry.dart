import 'package:flutter/material.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'text_background_controls.dart';
import 'rectangle_background_controls.dart';
import 'brush_background_controls.dart';

/// Registry quản lý việc khởi tạo các bộ điều khiển hình nền.
/// Khi thêm Style mới, chỉ cần thêm Mapping vào đây.
class BackgroundControlsRegistry {
  static final Map<TextBackgroundStyle, TextBackgroundControls> _strategies = {
    TextBackgroundStyle.rectangle: RectangleBackgroundControls(),
    TextBackgroundStyle.brush: BrushBackgroundControls(),
  };

  /// Trả về danh sách widgets điều khiển tương ứng với style.
  static List<Widget> build({
    required BuildContext context,
    required CustomTextOverlay text,
    required VideoPosterStore store,
  }) {
    final strategy = _strategies[text.backgroundStyle];
    
    if (strategy == null) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Chưa có bộ điều khiển cho style này'),
        )
      ];
    }

    return strategy.buildControls(
      context: context,
      text: text,
      store: store,
    );
  }
}
