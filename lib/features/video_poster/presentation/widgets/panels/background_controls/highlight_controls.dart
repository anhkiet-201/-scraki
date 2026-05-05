import 'package:flutter/material.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import '../../../stores/video_poster_store.dart';
import 'text_background_controls.dart';
import '../common/panel_components.dart';

class HighlightBackgroundControls implements TextBackgroundControls {
  @override
  List<Widget> buildControls({
    required BuildContext context,
    required CustomTextOverlay text,
    required VideoPosterStore store,
  }) {
    return [
      PanelComponents.buildLabeledSlider(
        context: context,
        label: 'BO GÓC NỀN (RADIUS): ${text.backgroundRadius.toInt()}px',
        value: text.backgroundRadius,
        min: 0,
        max: 40,
        onChanged: (v) => store.updateCustomTextStyle(text.id, backgroundRadius: v),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light 
              ? Colors.black.withValues(alpha: 0.05) 
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Mẹo: Bọc chữ trong dấu * để highlight.\nVí dụ: Đây là phần *quan trọng*',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
