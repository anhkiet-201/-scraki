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
          right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
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
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: texts.length,
        shrinkWrap: true,
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
                    ? _accentColor.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04),
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
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12),
            Text(
              'Nhấn "+ THÊM CHỮ"\nrồi kéo thả lên video',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.25),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // ── Section: TYPOGRAPHY (VĂN BẢN) ──
          PanelComponents.buildPanelSection(
            title: 'CHỮ & ĐỊNH DẠNG',
            icon: Icons.font_download_rounded,
            initiallyExpanded: true,
            children: [
              PanelComponents.buildSectionLabel('FONT CHỮ'),
              const SizedBox(height: 8),
              PanelComponents.buildFontPicker(
                currentFont: text.fontFamily ?? 'Roboto',
                onFontSelected: (font) =>
                    store.updateCustomTextStyle(text.id, fontFamily: font),
              ),
              const SizedBox(height: 16),
              PanelComponents.buildPanelRow(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PanelComponents.buildSectionLabel(
                        'CỠ CHỮ: ${text.fontSize.toInt()}px',
                      ),
                      PanelComponents.buildSlider(
                        context: context,
                        value: text.fontSize,
                        min: 8,
                        max: 120,
                        onChanged: (v) =>
                            store.updateCustomTextFontSize(text.id, v),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PanelComponents.buildSectionLabel(
                        'DÒNG: ${(text.textHeight ?? 1.2).toStringAsFixed(1)}x',
                      ),
                      PanelComponents.buildSlider(
                        context: context,
                        value: text.textHeight ?? 1.2,
                        min: 0.8,
                        max: 3.0,
                        divisions: 44,
                        onChanged: (v) =>
                            store.updateCustomTextStyle(text.id, textHeight: v),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PanelComponents.buildPanelRow(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PanelComponents.buildSectionLabel(
                        'K.CÁCH: ${text.letterSpacing.toStringAsFixed(1)}',
                      ),
                      PanelComponents.buildSlider(
                        context: context,
                        value: text.letterSpacing,
                        min: -5,
                        max: 20,
                        onChanged: (v) => store.updateCustomTextStyle(text.id,
                            letterSpacing: v),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PanelComponents.buildSectionLabel(
                        'XOAY: ${text.rotation.toInt()}°',
                      ),
                      PanelComponents.buildSlider(
                        context: context,
                        value: text.rotation,
                        min: -180,
                        max: 180,
                        divisions: 360,
                        onChanged: (v) =>
                            store.updateCustomTextStyle(text.id, rotation: v),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  const SizedBox(
                    height: 24,
                    child: VerticalDivider(color: Colors.white10),
                  ),
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
            ],
          ),

          // ── Section: APPEARANCE (MÀU SẮC & NỀN) ──
          PanelComponents.buildPanelSection(
            title: 'MÀU SẮC & NỀN',
            icon: Icons.palette_rounded,
            initiallyExpanded: true,
            children: [
              PanelComponents.buildSectionLabel('MÀU CHỮ'),
              const SizedBox(height: 8),
              if (store.recentTextColors.isNotEmpty) ...[
                PanelComponents.buildRecentColors(
                  colors: store.recentTextColors.toList(),
                  selectedColor: text.color,
                  onSelect: (c) => store.updateCustomTextStyle(text.id, color: c),
                ),
                const SizedBox(height: 8),
                PanelComponents.buildPaletteDivider(),
                const SizedBox(height: 8),
              ],
              PanelComponents.buildColorPalette(
                context: context,
                colors: PanelComponents.colorPalette,
                selectedColor: text.color,
                onSelect: (c) => store.updateCustomTextStyle(text.id, color: c),
                onPickCustom: () => PanelComponents.showColorPicker(
                  context: context,
                  initialColor: text.color,
                  onColorSelected: (c) =>
                      store.updateCustomTextStyle(text.id, color: c),
                ),
              ),
              const SizedBox(height: 20),
              PanelComponents.buildSectionLabel('MÀU NỀN'),
              const SizedBox(height: 8),
              if (store.recentBgColors.isNotEmpty) ...[
                PanelComponents.buildRecentColors(
                  colors: store.recentBgColors.toList(),
                  selectedColor: text.backgroundColor,
                  onSelect: (c) =>
                      store.updateCustomTextStyle(text.id, backgroundColor: c),
                ),
                const SizedBox(height: 8),
                PanelComponents.buildPaletteDivider(),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  GestureDetector(
                    onTap: () => store.updateCustomTextStyle(
                      text.id,
                      clearBackgroundColor: true,
                    ),
                    child: Container(
                      width: 28, height: 28,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: text.backgroundColor == null ? _accentColor : Colors.white10,
                          width: text.backgroundColor == null ? 2 : 1,
                        ),
                      ),
                      child: const Icon(Icons.block_rounded, size: 14, color: Colors.white38),
                    ),
                  ),
                  Expanded(
                    child: PanelComponents.buildColorPalette(
                      context: context,
                      colors: PanelComponents.darkColorPalette,
                      selectedColor: text.backgroundColor,
                      onSelect: (c) => store.updateCustomTextStyle(text.id, backgroundColor: c),
                      onPickCustom: () => PanelComponents.showColorPicker(
                        context: context,
                        initialColor: text.backgroundColor ?? Colors.black,
                        onColorSelected: (c) => store.updateCustomTextStyle(text.id, backgroundColor: c),
                      ),
                    ),
                  ),
                ],
              ),
              if (text.backgroundColor != null) ...[
                const SizedBox(height: 16),
                PanelComponents.buildPanelRow(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PanelComponents.buildSectionLabel(
                          'ĐỘ MỜ: ${(text.backgroundOpacity * 100).toInt()}%',
                        ),
                        PanelComponents.buildSlider(
                          context: context,
                          value: text.backgroundOpacity,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (v) => store.updateCustomTextStyle(text.id,
                              backgroundOpacity: v),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PanelComponents.buildSectionLabel(
                          'BO GÓC: ${text.backgroundRadius.toInt()}px',
                        ),
                        PanelComponents.buildSlider(
                          context: context,
                          value: text.backgroundRadius,
                          min: 0,
                          max: 100,
                          onChanged: (v) => store.updateCustomTextStyle(text.id,
                              backgroundRadius: v),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),

          // ── Section: BORDER & EFFECTS (VIỀN & HIỆU ỨNG) ──
          PanelComponents.buildPanelSection(
            title: 'VIỀN & HIỆU ỨNG',
            icon: Icons.auto_awesome_rounded,
            children: [
              PanelComponents.buildSectionLabel('VIỀN CHỮ'),
              const SizedBox(height: 8),
              if (store.recentStrokeColors.isNotEmpty) ...[
                PanelComponents.buildRecentColors(
                  colors: store.recentStrokeColors.toList(),
                  selectedColor: text.strokeColor,
                  onSelect: (c) {
                    store.updateCustomTextStyle(text.id, strokeColor: c);
                    if (text.strokeWidth == 0) {
                      store.updateCustomTextStyle(text.id, strokeWidth: 2.0);
                    }
                  },
                ),
                const SizedBox(height: 8),
                PanelComponents.buildPaletteDivider(),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  GestureDetector(
                    onTap: () => store.updateCustomTextStyle(text.id, strokeWidth: 0, clearStrokeColor: true),
                    child: Container(
                      width: 28, height: 28,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (text.strokeWidth == 0 || text.strokeColor == null) ? _accentColor : Colors.white10,
                          width: (text.strokeWidth == 0 || text.strokeColor == null) ? 2 : 1,
                        ),
                      ),
                      child: const Icon(Icons.block_rounded, size: 14, color: Colors.white38),
                    ),
                  ),
                  Expanded(
                    child: PanelComponents.buildColorPalette(
                      context: context,
                      colors: PanelComponents.colorPalette,
                      selectedColor: text.strokeColor,
                      onSelect: (c) {
                        store.updateCustomTextStyle(text.id, strokeColor: c);
                        if (text.strokeWidth == 0) store.updateCustomTextStyle(text.id, strokeWidth: 2.0);
                      },
                      onPickCustom: () => PanelComponents.showColorPicker(
                        context: context,
                        initialColor: text.strokeColor ?? Colors.white,
                        onColorSelected: (c) => store.updateCustomTextStyle(text.id, strokeColor: c),
                      ),
                    ),
                  ),
                ],
              ),
              if (text.strokeColor != null && text.strokeWidth > 0) ...[
                const SizedBox(height: 8),
                PanelComponents.buildSectionLabel('ĐỘ DÀY VIỀN CHỮ: ${text.strokeWidth.toInt()}px'),
                PanelComponents.buildSlider(
                  context: context,
                  value: text.strokeWidth.clamp(1.0, 20.0),
                  min: 1, max: 20,
                  onChanged: (v) => store.updateCustomTextStyle(text.id, strokeWidth: v),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),

          // ── Section: HIỆU ỨNG VÀO (IN) ──
          PanelComponents.buildPanelSection(
            title: 'HIỆU ỨNG XUẤT HIỆN (IN)',
            icon: Icons.login_rounded,
            children: [
              PanelComponents.buildSectionLabel('LOẠI HIỆU ỨNG'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TextAnimationType>(
                    value: text.animationInType,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E1E),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                    items: const [
                      DropdownMenuItem(value: TextAnimationType.none, child: Text('Không hiệu ứng')),
                      DropdownMenuItem(value: TextAnimationType.fade, child: Text('Hiện dần (Fade)')),
                      DropdownMenuItem(value: TextAnimationType.zoom, child: Text('Phóng to (Zoom)')),
                      DropdownMenuItem(value: TextAnimationType.slideUp, child: Text('Trượt từ dưới lên')),
                      DropdownMenuItem(value: TextAnimationType.slideDown, child: Text('Trượt từ trên xuống')),
                      DropdownMenuItem(value: TextAnimationType.slideLeft, child: Text('Trượt từ phải sang')),
                      DropdownMenuItem(value: TextAnimationType.slideRight, child: Text('Trượt từ trái sang')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        store.updateCustomTextAnimationIn(text.id, v, text.animationInDuration);
                      }
                    },
                  ),
                ),
              ),
              if (text.animationInType != TextAnimationType.none) ...[
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final totalDuration = (text.endTime ?? 40.0) - text.startTime;
                    // Current Out duration limit based on In
                    final maxIn = (1.0 - text.animationOutDuration).clamp(0.05, 1.0);
                    final safeValue = text.animationInDuration.clamp(0.01, maxIn).toDouble();
                    final inSeconds = totalDuration * safeValue;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PanelComponents.buildSectionLabel('THỜI GIAN HIỆN: ${(safeValue * 100).toInt()}% (${inSeconds.toStringAsFixed(1)}s)'),
                        PanelComponents.buildSlider(
                          context: context,
                          value: safeValue,
                          min: 0.0,
                          max: 1.0,
                          divisions: 99,
                          onChanged: (v) => store.updateCustomTextAnimationIn(text.id, text.animationInType, v.clamp(0.01, maxIn)),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => store.triggerPreviewAnimation(text.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accentColor,
                      side: BorderSide(color: _accentColor.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                    label: const Text(
                      '▶ XEM TRƯỚC HIỆU ỨNG VÀO',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // ── Section: HIỆU ỨNG RA (OUT) ──
          PanelComponents.buildPanelSection(
            title: 'HIỆU ỨNG BIẾN MẤT (OUT)',
            icon: Icons.logout_rounded,
            children: [
              PanelComponents.buildSectionLabel('LOẠI HIỆU ỨNG'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TextAnimationType>(
                    value: text.animationOutType,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E1E),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                    items: const [
                      DropdownMenuItem(value: TextAnimationType.none, child: Text('Không hiệu ứng')),
                      DropdownMenuItem(value: TextAnimationType.fade, child: Text('Mờ dần (Fade)')),
                      DropdownMenuItem(value: TextAnimationType.zoom, child: Text('Thu nhỏ (Zoom)')),
                      DropdownMenuItem(value: TextAnimationType.slideUp, child: Text('Trượt lên trên')),
                      DropdownMenuItem(value: TextAnimationType.slideDown, child: Text('Trượt xuống dưới')),
                      DropdownMenuItem(value: TextAnimationType.slideLeft, child: Text('Trượt sang trái')),
                      DropdownMenuItem(value: TextAnimationType.slideRight, child: Text('Trượt sang phải')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        store.updateCustomTextAnimationOut(text.id, v, text.animationOutDuration);
                      }
                    },
                  ),
                ),
              ),
              if (text.animationOutType != TextAnimationType.none) ...[
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final totalDuration = (text.endTime ?? 40.0) - text.startTime;
                    // Limit Out duration so it doesn't overlap with In
                    final maxOut = (1.0 - text.animationInDuration).clamp(0.05, 1.0);
                    final safeValue = text.animationOutDuration.clamp(0.01, maxOut).toDouble();
                    final outSeconds = totalDuration * safeValue;
                    
                    // Full track visual [0.0, 1.0] but isReversed: true
                    // Value is (1.0 - duration) so it sits at the end.
                    final minVisualLimit = (1.0 - maxOut).toDouble();
                    final visualValue = (1.0 - safeValue).clamp(minVisualLimit, 1.0);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PanelComponents.buildSectionLabel('THỜI GIAN MỜ: ${(safeValue * 100).toInt()}% (${outSeconds.toStringAsFixed(1)}s)'),
                        PanelComponents.buildSlider(
                          context: context,
                          value: visualValue,
                          min: 0.0,
                          max: 1.0,
                          divisions: 99,
                          isReversed: true,
                          onChanged: (v) {
                            // Convert visual value back to duration: duration = 1.0 - visual
                            // Limit visual value to at least 1.0 - maxOut
                            final cappedVisual = v.clamp(minVisualLimit, 1.0);
                            store.updateCustomTextAnimationOut(text.id, text.animationOutType, 1.0 - cappedVisual);
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => store.triggerPreviewAnimationOut(text.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accentColor,
                      side: BorderSide(color: _accentColor.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                    label: const Text(
                      '▶ XEM TRƯỚC HIỆU ỨNG RA',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // ── Section: TIMELINE ──
          PanelComponents.buildPanelSection(
            title: 'THỜI GIAN HIỂN THỊ',
            icon: Icons.timer_rounded,
            children: [
              _buildTimeInput(
                label: 'BẮT ĐẦU (s)',
                value: text.startTime,
                onChanged: (v) => store.updateCustomTextTiming(text.id, startTime: v),
                maxValue: 40.0,
              ),
              const SizedBox(height: 12),
              _buildTimeInput(
                label: 'KẾT THÚC (s)',
                value: text.endTime,
                hint: 'Xuyên suốt',
                maxValue: 40.0,
                onChanged: (v) => v == null 
                    ? store.updateCustomTextTiming(text.id, clearEndTime: true)
                    : store.updateCustomTextTiming(text.id, endTime: v),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimeInput({
    required String label,
    required double? value,
    required void Function(double?) onChanged,
    String? hint,
    double maxValue = 9999.0,
  }) {
    return TimeInputField(
      label: label,
      initialValue: value,
      onChanged: onChanged,
      hint: hint,
      maxValue: maxValue,
    );
  }
}
