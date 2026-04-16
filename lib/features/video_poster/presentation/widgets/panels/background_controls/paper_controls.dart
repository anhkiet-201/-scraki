import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import '../../../stores/video_poster_store.dart';
import '../common/panel_components.dart';
import 'text_background_controls.dart';

class PaperBackgroundControls implements TextBackgroundControls {
  @override
  List<Widget> buildControls({
    required BuildContext context,
    required CustomTextOverlay text,
    required VideoPosterStore store,
  }) {
    return [
      Observer(
        builder: (_) {
          // Lấy text overlay mới nhất từ store dựa trên id để đảm bảo tính quan sát (observability)
          final latestText = store.customTexts.firstWhere((t) => t.id == text.id, orElse: () => text);
          final params = latestText.styleParams;
          
          return PanelComponents.buildPanelRow(
            children: [
              PanelComponents.buildLabeledSlider(
                context: context,
                label: 'ĐỘ NHÁM CẠNH: ${((params['paper_roughness'] as num?) ?? 1.5).toStringAsFixed(1)}',
                value: (params['paper_roughness'] as num?)?.toDouble() ?? 1.5,
                min: 0.1,
                max: 5.0,
                onChanged: (v) => store.updateCustomTextStyle(latestText.id, styleParams: {'paper_roughness': v}),
              ),
            ],
          );
        },
      ),
    ];
  }
}
