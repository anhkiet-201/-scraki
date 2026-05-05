import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import '../../../stores/video_poster_store.dart';
import 'text_background_controls.dart';
import '../common/panel_components.dart';

class QuoteBackgroundControls implements TextBackgroundControls {
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
          final barWidth = (params['quote_bar_width'] as num?)?.toDouble() ?? 4.0;
          final bgOpacity = (params['quote_bg_opacity'] as num?)?.toDouble() ?? 0.2;

          return Column(
            children: [
              PanelComponents.buildLabeledSlider(
                context: context,
                label: 'ĐỘ DÀY THANH DỌC: ${barWidth.toInt()}px',
                value: barWidth,
                min: 1,
                max: 20,
                onChanged: (v) => store.updateCustomTextStyle(
                  latestText.id,
                  styleParams: {'quote_bar_width': v},
                ),
              ),
              const SizedBox(height: 16),
              PanelComponents.buildLabeledSlider(
                context: context,
                label: 'ĐỘ ĐẬM NỀN PHỤ: ${(bgOpacity * 100).toInt()}%',
                value: bgOpacity,
                min: 0,
                max: 1,
                onChanged: (v) => store.updateCustomTextStyle(
                  latestText.id,
                  styleParams: {'quote_bg_opacity': v},
                ),
              ),
            ],
          );
        },
      ),
    ];
  }
}
