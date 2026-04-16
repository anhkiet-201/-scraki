import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
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
      Observer(
        builder: (_) {
          final latestText = store.customTexts.firstWhere((t) => t.id == text.id, orElse: () => text);
          
          return Column(
            children: [
              PanelComponents.buildPanelRow(
                children: [
                  PanelComponents.buildLabeledSlider(
                    context: context,
                    label: 'ĐỘ MỜ: ${(latestText.backgroundOpacity * 100).toInt()}%',
                    value: latestText.backgroundOpacity,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) => store.updateCustomTextStyle(
                      latestText.id,
                      backgroundOpacity: v,
                    ),
                  ),
                  PanelComponents.buildLabeledSlider(
                    context: context,
                    label: 'ĐỘ RUNG: ${latestText.brushIntensity.toStringAsFixed(1)}',
                    value: latestText.brushIntensity,
                    min: 0.0,
                    max: 10.0,
                    onChanged: (v) => store.updateCustomTextStyle(
                      latestText.id,
                      brushIntensity: v,
                    ),
                  ),
                ],
              ),
              PanelComponents.buildPanelRow(
                children: [
                  PanelComponents.buildLabeledSlider(
                    context: context,
                    label: 'ĐỘ DÀY: ${latestText.brushThickness.toStringAsFixed(1)}',
                    value: latestText.brushThickness,
                    min: 0.5,
                    max: 3.0,
                    onChanged: (v) => store.updateCustomTextStyle(
                      latestText.id,
                      brushThickness: v,
                    ),
                  ),
                  PanelComponents.buildLabeledSlider(
                    context: context,
                    label: 'SỐ VỆT: ${latestText.brushComplexity.toInt()}',
                    value: latestText.brushComplexity,
                    min: 1,
                    max: 40,
                    onChanged: (v) => store.updateCustomTextStyle(
                      latestText.id,
                      brushComplexity: v,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ];
  }
}
