import 'package:flutter/material.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

/// Interface cho các bộ điều khiển hình nền văn bản (Strategy Pattern).
/// Mỗi kiểu nền (Background Style) sẽ thực thi interface này để hiển thị UI riêng biệt.
abstract class TextBackgroundControls {
  List<Widget> buildControls({
    required BuildContext context,
    required CustomTextOverlay text,
    required VideoPosterStore store,
  });
}
