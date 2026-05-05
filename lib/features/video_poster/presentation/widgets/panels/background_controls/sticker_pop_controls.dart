import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import '../../../stores/video_poster_store.dart';
import '../common/panel_components.dart';
import 'text_background_controls.dart';

class StickerPopBackgroundControls implements TextBackgroundControls {
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
          
          final offset = (params['sticker_offset'] as num?)?.toDouble() ?? 6.0;
          final accentColorInt = (params['sticker_3d_color'] as int?) ?? 0xFFFFC107;
          final shadowColorInt = (params['sticker_shadow_color'] as int?) ?? 0xFF000000;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Shadow Offset
              PanelComponents.buildLabeledSlider(
                context: context,
                label: 'ĐỘ LỆCH 3D: ${offset.toInt()}px',
                value: offset,
                min: 0,
                max: 30,
                onChanged: (v) => store.updateCustomTextStyle(
                  latestText.id,
                  styleParams: {'sticker_offset': v},
                ),
              ),
              const SizedBox(height: 16),

              // 2. Màu Chữ 3D (Accent - Vàng trong mẫu)
              PanelComponents.buildSectionLabel('MÀU CHỮ 3D (LỚP VÀNG)', context: context),
              const SizedBox(height: 8),
              PanelComponents.buildColorPalette(
                context: context,
                colors: PanelComponents.vibrantColorPalette,
                selectedColor: Color(accentColorInt),
                onSelect: (c) => store.updateCustomTextStyle(
                  latestText.id,
                  styleParams: {'sticker_3d_color': c.value},
                ),
                onPickCustom: () => PanelComponents.showColorPicker(
                  context: context,
                  initialColor: Color(accentColorInt),
                  onColorSelected: (c) => store.updateCustomTextStyle(
                    latestText.id,
                    styleParams: {'sticker_3d_color': c.value},
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Màu Bóng Shadow (Shadow - Đen trong mẫu)
              PanelComponents.buildSectionLabel('MÀU BÓNG SHADOW (LỚP ĐEN)', context: context),
              const SizedBox(height: 8),
              PanelComponents.buildColorPalette(
                context: context,
                colors: [Colors.black, Colors.grey, Colors.blueGrey, ...PanelComponents.colorPalette.take(5)],
                selectedColor: Color(shadowColorInt),
                onSelect: (c) => store.updateCustomTextStyle(
                  latestText.id,
                  styleParams: {'sticker_shadow_color': c.value},
                ),
                onPickCustom: () => PanelComponents.showColorPicker(
                  context: context,
                  initialColor: Color(shadowColorInt),
                  onColorSelected: (c) => store.updateCustomTextStyle(
                    latestText.id,
                    styleParams: {'sticker_shadow_color': c.value},
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1, color: Colors.white10),
              const SizedBox(height: 16),
              
              const Text(
                'Mẹo: Chỉnh "Viền chữ" (Stroke) và "Màu nền" thành màu trắng để có hiệu ứng sticker hoàn hảo như ảnh mẫu.',
                style: TextStyle(fontSize: 10, color: Colors.white38, fontStyle: FontStyle.italic),
              ),
            ],
          );
        },
      ),
    ];
  }
}
