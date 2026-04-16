import 'package:flutter/material.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/common/panel_components.dart';
import 'text_background_controls.dart';

/// Triển khai điều khiển cho kiểu nền Vệt cọ (Brush).
class BrushBackgroundControls implements TextBackgroundControls {
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
            label: 'ĐỘ RUNG: ${text.brushIntensity.toStringAsFixed(1)}',
            value: text.brushIntensity,
            min: 0.0,
            max: 10.0,
            onChanged: (v) => store.updateCustomTextStyle(
              text.id,
              brushIntensity: v,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      PanelComponents.buildPanelRow(
        children: [
          PanelComponents.buildLabeledSlider(
            context: context,
            label: 'ĐỘ DÀY: ${text.brushThickness.toStringAsFixed(1)}',
            value: text.brushThickness,
            min: 0.5,
            max: 3.0,
            onChanged: (v) => store.updateCustomTextStyle(
              text.id,
              brushThickness: v,
            ),
          ),
          PanelComponents.buildLabeledSlider(
            context: context,
            label: 'SỐ VỆT: ${text.brushComplexity.toInt()}',
            value: text.brushComplexity,
            min: 1,
            max: 40,
            onChanged: (v) => store.updateCustomTextStyle(
              text.id,
              brushComplexity: v,
            ),
          ),
        ],
      ),
    ];
  }
}
