import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/presentation/widgets/form/time_input_field.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/common/panel_components.dart';

/// Panel hiển thị khi tab TEXT được chọn.
/// Cho phép thêm/chọn/xóa text và chỉnh style.
class TextPropertiesPanel extends StatelessWidget {
  final VideoPosterStore store;

  const TextPropertiesPanel({super.key, required this.store});

  static const _accentColor = PanelComponents.kPanelAccentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Observer(
              builder: (_) {
                final texts = store.customTexts;
                final selectedId = store.selectedCustomTextId;
                final selected = texts.isEmpty
                    ? null
                    : selectedId != null
                    ? texts.cast<CustomTextOverlay?>().firstWhere(
                        (t) => t?.id == selectedId,
                        orElse: () => null,
                      )
                    : null;

                return Column(
                  children: [
                    if (texts.isNotEmpty)
                      _buildTextList(context, texts.toList(), selectedId),
                    if (selected != null) ...[
                      const Divider(color: Colors.white10, height: 1),
                      Expanded(child: _buildProperties(context, selected)),
                    ] else
                      Expanded(child: _buildEmptyHint()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VĂN BẢN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: store.addCustomText,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.text_fields_rounded, size: 18),
              label: const Text(
                '+ THÊM CHỮ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextList(
    BuildContext context,
    List<CustomTextOverlay> texts,
    String? selectedId,
  ) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: texts.length,
        itemBuilder: (_, i) {
          final t = texts[i];
          final isActive = t.id == selectedId;
          return GestureDetector(
            onTap: () => store.selectCustomText(t.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? _accentColor.withOpacity(0.15)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: isActive
                    ? Border.all(color: _accentColor, width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.text_fields_rounded,
                    size: 14,
                    color: isActive ? _accentColor : Colors.white38,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.label.isEmpty ? '(trống)' : t.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.white : Colors.white54,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => store.removeCustomText(t.id),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.text_fields_rounded,
              size: 40,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 12),
            Text(
              'Nhấn "+ THÊM CHỮ"\nrồi kéo thả lên video',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.25),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProperties(BuildContext context, CustomTextOverlay text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Style Toggles ──
          PanelComponents.buildSectionLabel('ĐỊNH DẠNG'),
          const SizedBox(height: 8),
          Row(
            children: [
              PanelComponents.buildToggleButton(
                icon: Icons.format_bold_rounded,
                active: text.fontWeight == FontWeight.bold,
                onTap: () => store.updateCustomTextStyle(
                  text.id,
                  fontWeight: text.fontWeight == FontWeight.bold
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              PanelComponents.buildToggleButton(
                icon: Icons.format_italic_rounded,
                active: text.fontStyle == FontStyle.italic,
                onTap: () => store.updateCustomTextStyle(
                  text.id,
                  fontStyle: text.fontStyle == FontStyle.italic
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
              const SizedBox(width: 16),
              PanelComponents.buildAlignButton(
                icon: Icons.format_align_left_rounded,
                active: text.textAlign == TextAlign.left,
                onTap: () => store.updateCustomTextStyle(
                  text.id,
                  textAlign: TextAlign.left,
                ),
              ),
              PanelComponents.buildAlignButton(
                icon: Icons.format_align_center_rounded,
                active: text.textAlign == TextAlign.center,
                onTap: () => store.updateCustomTextStyle(
                  text.id,
                  textAlign: TextAlign.center,
                ),
              ),
              PanelComponents.buildAlignButton(
                icon: Icons.format_align_right_rounded,
                active: text.textAlign == TextAlign.right,
                onTap: () => store.updateCustomTextStyle(
                  text.id,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Font Size ──
          PanelComponents.buildSectionLabel('CỠ CHỮ  ${text.fontSize.toInt()}px'),
          const SizedBox(height: 4),
          PanelComponents.buildSlider(
            context: context,
            value: text.fontSize,
            min: 8,
            max: 120,
            onChanged: (v) => store.updateCustomTextFontSize(text.id, v),
            accentColor: _accentColor,
          ),

          const SizedBox(height: 12),

          // ── Letter Spacing ──
          PanelComponents.buildSectionLabel('KHOẢNG CÁCH CHỮ  ${text.letterSpacing.toStringAsFixed(1)}'),
          const SizedBox(height: 4),
          PanelComponents.buildSlider(
            context: context,
            value: text.letterSpacing,
            min: -2.0,
            max: 10.0,
            divisions: 60,
            onChanged: (v) =>
                store.updateCustomTextStyle(text.id, letterSpacing: v),
            accentColor: _accentColor,
          ),

          const SizedBox(height: 12),

          // ── Line Height ──
          PanelComponents.buildSectionLabel(
            'KHOẢNG CÁCH DÒNG  ${(text.textHeight ?? 1.2).toStringAsFixed(1)}x',
          ),
          const SizedBox(height: 4),
          PanelComponents.buildSlider(
            context: context,
            value: text.textHeight ?? 1.2,
            min: 0.8,
            max: 3.0,
            divisions: 44,
            onChanged: (v) =>
                store.updateCustomTextStyle(text.id, textHeight: v),
            accentColor: _accentColor,
          ),

          const SizedBox(height: 12),

          // ── Rotation ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PanelComponents.buildSectionLabel('XOAY  ${text.rotation.toInt()}°'),
              if (text.rotation != 0)
                GestureDetector(
                  onTap: () =>
                      store.updateCustomTextStyle(text.id, rotation: 0),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text(
                      'RESET',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          PanelComponents.buildSlider(
            context: context,
            value: text.rotation,
            min: -180,
            max: 180,
            divisions: 360,
            onChanged: (v) => store.updateCustomTextStyle(text.id, rotation: v),
            accentColor: _accentColor,
          ),

          const SizedBox(height: 16),
          // ── Timing ──
          PanelComponents.buildSectionLabel('THỜI GIAN XUẤT HIỆN'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTimeInput(
                  label: 'BẮT ĐẦU (s)',
                  value: text.startTime,
                  onChanged: (double? v) =>
                      store.updateCustomTextTiming(text.id, startTime: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeInput(
                  label: 'KẾT THÚC (s)',
                  value: text.endTime,
                  hint: 'Xuyên suốt',
                  onChanged: (double? v) {
                    if (v == null) {
                      store.updateCustomTextTiming(text.id, clearEndTime: true);
                    } else {
                      store.updateCustomTextTiming(text.id, endTime: v);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Font Family ──
          PanelComponents.buildSectionLabel('FONT CHỮ'),
          const SizedBox(height: 8),
          PanelComponents.buildFontPicker(
            currentFont: text.fontFamily ?? 'Roboto',
            onFontSelected: (font) =>
                store.updateCustomTextStyle(text.id, fontFamily: font),
          ),

          const SizedBox(height: 16),

          // ── Text Color ──
          PanelComponents.buildSectionLabel('MÀU CHỮ'),
          const SizedBox(height: 8),
          if (store.recentTextColors.isNotEmpty) ...[
            PanelComponents.buildRecentColors(
              colors: store.recentTextColors.toList(),
              selectedColor: text.color,
              onSelect: (Color c) => store.updateCustomTextStyle(text.id, color: c),
              accentColor: _accentColor,
            ),
            const SizedBox(height: 10),
            PanelComponents.buildPaletteDivider(),
            const SizedBox(height: 8),
          ],
          PanelComponents.buildColorPalette(
            context: context,
            colors: PanelComponents.colorPalette,
            selectedColor: text.color,
            onSelect: (c) => store.updateCustomTextStyle(text.id, color: c),
            accentColor: _accentColor,
            onPickCustom: () => PanelComponents.showColorPicker(
              context: context,
              initialColor: text.color,
              onColorSelected: (c) =>
                  store.updateCustomTextStyle(text.id, color: c),
              accentColor: _accentColor,
            ),
          ),

          const SizedBox(height: 16),

          // ── Background Color ──
          PanelComponents.buildSectionLabel('MÀU NỀN'),
          const SizedBox(height: 8),
          if (store.recentBgColors.isNotEmpty) ...[
            PanelComponents.buildRecentColors(
              colors: store.recentBgColors.toList(),
              selectedColor: text.backgroundColor,
              onSelect: (Color c) =>
                  store.updateCustomTextStyle(text.id, backgroundColor: c),
              accentColor: _accentColor,
            ),
            const SizedBox(height: 10),
            PanelComponents.buildPaletteDivider(),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              // No background (transparent)
              GestureDetector(
                onTap: () => store.updateCustomTextStyle(
                  text.id,
                  clearBackgroundColor: true,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: text.backgroundColor == null
                          ? _accentColor
                          : Colors.white24,
                      width: text.backgroundColor == null ? 2.5 : 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    size: 14,
                    color: Colors.white38,
                  ),
                ),
              ),
              Expanded(
                child: PanelComponents.buildColorPalette(
                  context: context,
                  colors: PanelComponents.darkColorPalette,
                  selectedColor: text.backgroundColor,
                  onSelect: (c) =>
                      store.updateCustomTextStyle(text.id, backgroundColor: c),
                  accentColor: _accentColor,
                  onPickCustom: () => PanelComponents.showColorPicker(
                    context: context,
                    initialColor: text.backgroundColor ?? Colors.black,
                    onColorSelected: (c) => store.updateCustomTextStyle(text.id,
                        backgroundColor: c),
                    accentColor: _accentColor,
                  ),
                ),
              ),
            ],
          ),

          if (text.backgroundColor != null) ...[
            const SizedBox(height: 8),
            PanelComponents.buildSectionLabel(
              'ĐỘ MỜ NỀN  ${(text.backgroundOpacity * 100).toInt()}%',
            ),
            const SizedBox(height: 4),
            PanelComponents.buildSlider(
              context: context,
              value: text.backgroundOpacity,
              min: 0.05,
              max: 1.0,
              divisions: 19,
              onChanged: (v) =>
                  store.updateCustomTextStyle(text.id, backgroundOpacity: v),
              accentColor: _accentColor,
            ),
            const SizedBox(height: 8),
            PanelComponents.buildSectionLabel(
              'BO GÓC NỀN  ${text.backgroundRadius.toInt()}px',
            ),
            const SizedBox(height: 4),
            PanelComponents.buildSlider(
              context: context,
              value: text.backgroundRadius,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) =>
                  store.updateCustomTextStyle(text.id, backgroundRadius: v),
              accentColor: _accentColor,
            ),
            const SizedBox(height: 12),

            // ── Background Border (Viền nền) ──
            PanelComponents.buildSectionLabel('VIỀN NỀN'),
            const SizedBox(height: 8),
            PanelComponents.buildColorPalette(
              context: context,
              colors: [
                Colors.white,
                Colors.black,
                ...store.recentBorderColors,
              ],
              selectedColor: text.backgroundBorderColor,
              onSelect: (c) => store.updateCustomTextStyle(
                text.id,
                backgroundBorderColor: c,
              ),
              accentColor: _accentColor,
              onPickCustom: () => PanelComponents.showColorPicker(
                context: context,
                initialColor: text.backgroundBorderColor ?? Colors.white,
                onColorSelected: (c) => store.updateCustomTextStyle(text.id,
                    backgroundBorderColor: c),
                accentColor: _accentColor,
              ),
            ),
            if (text.backgroundBorderColor != null) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => store.updateCustomTextStyle(
                  text.id,
                  clearBackgroundBorderColor: true,
                ),
                icon: const Icon(Icons.close_rounded,
                    size: 14, color: Colors.redAccent),
                label: const Text('BỎ VIỀN NỀN',
                    style: TextStyle(color: Colors.redAccent, fontSize: 10)),
              ),
            ],

            if (text.backgroundBorderColor != null) ...[
              const SizedBox(height: 8),
              PanelComponents.buildSectionLabel(
                'ĐỘ DÀY VIỀN NỀN  ${text.backgroundBorderWidth.toInt()}px',
              ),
              const SizedBox(height: 4),
              PanelComponents.buildSlider(
                context: context,
                value: text.backgroundBorderWidth,
                min: 0,
                max: 20,
                divisions: 20,
                onChanged: (v) => store.updateCustomTextStyle(text.id,
                    backgroundBorderWidth: v),
                accentColor: _accentColor,
              ),
            ],
          ],

          const SizedBox(height: 16),

          // ── Stroke (Viền chữ) ──
          PanelComponents.buildSectionLabel('VIỀN CHỮ'),
          const SizedBox(height: 8),
          if (store.recentStrokeColors.isNotEmpty) ...[
            PanelComponents.buildRecentColors(
              colors: store.recentStrokeColors.toList(),
              selectedColor: text.strokeColor,
              onSelect: (c) =>
                  store.updateCustomTextStyle(text.id, strokeColor: c),
              accentColor: _accentColor,
            ),
            const SizedBox(height: 10),
            PanelComponents.buildPaletteDivider(),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              // No stroke (transparent/width 0)
              GestureDetector(
                onTap: () => store.updateCustomTextStyle(
                  text.id,
                  strokeWidth: 0,
                  clearStrokeColor: true,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (text.strokeWidth == 0 || text.strokeColor == null)
                          ? _accentColor
                          : Colors.white24,
                      width: (text.strokeWidth == 0 || text.strokeColor == null)
                          ? 2.5
                          : 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    size: 14,
                    color: Colors.white38,
                  ),
                ),
              ),
              Expanded(
                child: PanelComponents.buildColorPalette(
                  context: context,
                  colors: PanelComponents.colorPalette,
                  selectedColor: text.strokeColor,
                  onSelect: (c) {
                    store.updateCustomTextStyle(text.id, strokeColor: c);
                    if (text.strokeWidth == 0) {
                      store.updateCustomTextStyle(text.id, strokeWidth: 2.0);
                    }
                  },
                  accentColor: _accentColor,
                  onPickCustom: () => PanelComponents.showColorPicker(
                    context: context,
                    initialColor: text.strokeColor ?? Colors.white,
                    onColorSelected: (c) {
                      store.updateCustomTextStyle(text.id, strokeColor: c);
                      if (text.strokeWidth == 0) {
                        store.updateCustomTextStyle(text.id, strokeWidth: 2.0);
                      }
                    },
                    accentColor: _accentColor,
                  ),
                ),
              ),
            ],
          ),

          if (text.strokeColor != null) ...[
            const SizedBox(height: 8),
            PanelComponents.buildSectionLabel('ĐỘ DÀY VIỀN  ${text.strokeWidth.toInt()}px'),
            const SizedBox(height: 4),
            PanelComponents.buildSlider(
              context: context,
              value: text.strokeWidth,
              min: 0,
              max: 20,
              divisions: 20,
              onChanged: (v) =>
                  store.updateCustomTextStyle(text.id, strokeWidth: v),
              accentColor: _accentColor,
            ),
          ],

          const SizedBox(height: 20),

          // ── Delete ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => store.removeCustomText(text.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.red, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text(
                'XÓA CHỮ NÀY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput({
    required String label,
    required double? value,
    required void Function(double?) onChanged,
    String? hint,
  }) {
    return TimeInputField(
      label: label,
      initialValue: value,
      onChanged: onChanged,
      hint: hint,
    );
  }
}

