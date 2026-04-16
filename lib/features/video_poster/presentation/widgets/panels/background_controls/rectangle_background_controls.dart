import 'package:flutter/material.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/common/panel_components.dart';
import 'text_background_controls.dart';

/// Triển khai điều khiển cho kiểu nền Hình chữ nhật (Rectangle).
class RectangleBackgroundControls implements TextBackgroundControls {
  @override
  List<Widget> buildControls({
    required BuildContext context,
    required CustomTextOverlay text,
    required VideoPosterStore store,
  }) {
    return [
      PanelComponents.buildPanelRow(
        children: [
          PanelComponents.buildLabeledSlider(
            context: context,
            label: 'ĐỘ MỜ: ${(text.backgroundOpacity * 100).toInt()}%',
            value: text.backgroundOpacity,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => store.updateCustomTextStyle(
              text.id,
              backgroundOpacity: v,
            ),
          ),
          PanelComponents.buildLabeledSlider(
            context: context,
            label: 'BO GÓC: ${text.backgroundRadius.toInt()}px',
            value: text.backgroundRadius,
            min: 0,
            max: 100,
            onChanged: (v) => store.updateCustomTextStyle(
              text.id,
              backgroundRadius: v,
            ),
          ),
        ],
      ),
    ];
  }
}
