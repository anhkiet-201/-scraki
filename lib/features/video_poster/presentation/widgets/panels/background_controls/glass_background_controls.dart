import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/common/panel_components.dart';
import 'text_background_controls.dart';

class GlassBackgroundControls implements TextBackgroundControls {
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
          final params = latestText.styleParams;
          
          return Column(
            children: [
              PanelComponents.buildLabeledSlider(
                context: context,
                label: 'BO GÓC: ${latestText.backgroundRadius.toInt()}px',
                value: latestText.backgroundRadius,
                min: 0,
                max: 100,
                onChanged: (v) => store.updateCustomTextStyle(latestText.id, backgroundRadius: v),
              ),
              const SizedBox(height: 8),
              PanelComponents.buildPanelRow(
                children: [
                  PanelComponents.buildLabeledSlider(
                    context: context,
                    label: 'ĐỘ MỜ NHÒE: ${((params['blur_sigma'] as double?) ?? 10.0).toInt()}',
                    value: (params['blur_sigma'] as double?) ?? 10.0,
                    min: 0.0,
                    max: 30.0,
                    onChanged: (v) => store.updateCustomTextStyle(latestText.id, styleParams: {'blur_sigma': v}),
                  ),
                  PanelComponents.buildLabeledSlider(
                    context: context,
                    label: 'ĐỘ TRONG (Kính): ${(((params['glass_opacity'] as double?) ?? 0.2) * 100).toInt()}%',
                    value: (params['glass_opacity'] as double?) ?? 0.2,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) => store.updateCustomTextStyle(latestText.id, styleParams: {'glass_opacity': v}),
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
