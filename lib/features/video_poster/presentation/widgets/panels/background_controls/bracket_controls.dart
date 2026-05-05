import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import '../../../stores/video_poster_store.dart';
import '../common/panel_components.dart';
import 'text_background_controls.dart';

class BracketBackgroundControls implements TextBackgroundControls {
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
          
          return PanelComponents.buildPanelRow(
            children: [
              PanelComponents.buildLabeledSlider(
                context: context,
                label: 'ĐỘ DÀY: ${((params['bracket_thickness'] as num?) ?? 2.0).toStringAsFixed(1)}',
                value: (params['bracket_thickness'] as num?)?.toDouble() ?? 2.0,
                min: 1.0,
                max: 10.0,
                onChanged: (v) => store.updateCustomTextStyle(latestText.id, styleParams: {'bracket_thickness': v}),
              ),
              PanelComponents.buildLabeledSlider(
                context: context,
                label: 'ĐỘ DÀI GÓC: ${((params['bracket_length'] as num?) ?? 12.0).toStringAsFixed(1)}',
                value: (params['bracket_length'] as num?)?.toDouble() ?? 12.0,
                min: 4.0,
                max: 50.0,
                onChanged: (v) => store.updateCustomTextStyle(latestText.id, styleParams: {'bracket_length': v}),
              ),
            ],
          );
        },
      ),
    ];
  }
}
