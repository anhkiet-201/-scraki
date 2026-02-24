import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

/// Panel hiển thị khi tab TEXT được chọn.
/// Cho phép thêm/chọn/xóa text và chỉnh style.
class TextPropertiesPanel extends StatelessWidget {
  final VideoPosterStore store;

  const TextPropertiesPanel({super.key, required this.store});

  static const _accentColor = Color(0xFF6366F1);

  /// Bảng màu chữ theo chuẩn Material 3 Color System.
  /// Sử dụng các tone 40, 60, 80, 90 từ các tonal palette chính thức.
  static const _colorPalette = <Color>[
    // Neutrals (Neutral Tonal Palette)
    Color(0xFFFFFFFF), // White
    Color(0xFFE6E1E5), // Neutral-90
    Color(0xFF938F99), // Neutral-60
    Color(0xFF1C1B1F), // Neutral-10 (Near black)
    // Primary (Purple / Default M3 seed)
    Color(0xFF6750A4), // Primary-40
    Color(0xFF9A82DB), // Primary-60
    Color(0xFFCFBCFF), // Primary-80
    Color(0xFFEADDFF), // Primary-95
    // Secondary
    Color(0xFF625B71), // Secondary-40
    Color(0xFF9A91A8), // Secondary-60
    Color(0xFFCCC2DC), // Secondary-80
    Color(0xFFE8DEF8), // Secondary-95
    // Tertiary (Pink / Rose)
    Color(0xFF7D5260), // Tertiary-40
    Color(0xFFB58392), // Tertiary-60
    Color(0xFFEFB8C8), // Tertiary-80
    Color(0xFFFFD8E4), // Tertiary-95
    // Error
    Color(0xFFB3261E), // Error-40
    Color(0xFFEC928E), // Error-70
    Color(0xFFF2B8B5), // Error-80
    // Tertiary Green (Custom seed)
    Color(0xFF386A20), // Green-40
    Color(0xFF57A640), // Green-50
    Color(0xFF8FC877), // Green-70
    Color(0xFFC5EDB5), // Green-90
    // Blue / Informational
    Color(0xFF0061A4), // Blue-40
    Color(0xFF4FA6E7), // Blue-60
    Color(0xFF9ECAFF), // Blue-80
    Color(0xFFD0E4FF), // Blue-95
    // Yellow / Warning
    Color(0xFF695F00), // Yellow-40
    Color(0xFFD2C148), // Yellow-70
    Color(0xFFEFE06D), // Yellow-80
  ];

  /// Bảng màu nền theo chuẩn Material 3 Color System.
  /// Sử dụng tone tối (10–30) làm nền để đảm bảo contrast tốt với văn bản.
  static const _bgColorPalette = <Color>[
    // Surface & Neutral dark (Neutral Tonal Palette)
    Color(0xFF1C1B1F), // Neutral-10
    Color(0xFF313033), // Neutral-20
    Color(0xFF48464C), // Neutral-30
    Color(0xFF787579), // Neutral-50
    Color(0xFFE6E1E5), // Neutral-90 (light)
    Color(0xFFFFFFFF), // Neutral-100
    // Primary container dark
    Color(0xFF21005D), // Primary-4
    Color(0xFF38006B), // Primary-10
    Color(0xFF4F378B), // Primary-30
    Color(0xFF6750A4), // Primary-40
    Color(0xFF9A82DB), // Primary-60
    // Secondary container dark
    Color(0xFF1D192B), // Secondary-6
    Color(0xFF332D41), // Secondary-20
    Color(0xFF4A4458), // Secondary-30
    // Tertiary container dark (Rose/Pink)
    Color(0xFF31111D), // Tertiary-6
    Color(0xFF492532), // Tertiary-20
    Color(0xFF633B48), // Tertiary-30
    // Error container dark
    Color(0xFF410002), // Error-6
    Color(0xFF690005), // Error-20
    Color(0xFF93000A), // Error-30
    // Green dark
    Color(0xFF072100), // Green-6
    Color(0xFF1A3D07), // Green-20
    // Blue dark
    Color(0xFF001D36), // Blue-6
    Color(0xFF003258), // Blue-20
  ];

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Style Toggles ──
          _buildSectionLabel('ĐỊNH DẠNG'),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildToggleButton(
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
              _buildToggleButton(
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
              _buildAlignButton(
                icon: Icons.format_align_left_rounded,
                active: text.textAlign == TextAlign.left,
                onTap: () => store.updateCustomTextStyle(
                  text.id,
                  textAlign: TextAlign.left,
                ),
              ),
              _buildAlignButton(
                icon: Icons.format_align_center_rounded,
                active: text.textAlign == TextAlign.center,
                onTap: () => store.updateCustomTextStyle(
                  text.id,
                  textAlign: TextAlign.center,
                ),
              ),
              _buildAlignButton(
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
          _buildSectionLabel('CỠ CHỮ  ${text.fontSize.toInt()}px'),
          const SizedBox(height: 4),
          _buildSlider(
            context: context,
            value: text.fontSize,
            min: 8,
            max: 120,
            onChanged: (v) => store.updateCustomTextFontSize(text.id, v),
          ),

          const SizedBox(height: 12),

          // ── Line Height ──
          _buildSectionLabel(
            'KHOẢNG CÁCH DÒNG  ${(text.textHeight ?? 1.2).toStringAsFixed(1)}x',
          ),
          const SizedBox(height: 4),
          _buildSlider(
            context: context,
            value: text.textHeight ?? 1.2,
            min: 0.8,
            max: 3.0,
            divisions: 44,
            onChanged: (v) =>
                store.updateCustomTextStyle(text.id, textHeight: v),
          ),

          const SizedBox(height: 16),

          // ── Text Color ──
          _buildSectionLabel('MÀU CHỮ'),
          const SizedBox(height: 8),
          _buildColorPalette(
            colors: _colorPalette,
            selectedColor: text.color,
            onSelect: (c) => store.updateCustomTextStyle(text.id, color: c),
          ),

          const SizedBox(height: 16),

          // ── Background Color ──
          _buildSectionLabel('MÀU NỀN'),
          const SizedBox(height: 8),
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
                child: _buildColorPalette(
                  colors: _bgColorPalette,
                  selectedColor: text.backgroundColor,
                  onSelect: (c) =>
                      store.updateCustomTextStyle(text.id, backgroundColor: c),
                ),
              ),
            ],
          ),

          if (text.backgroundColor != null) ...[
            const SizedBox(height: 8),
            _buildSectionLabel(
              'ĐỘ MỜ NỀN  ${(text.backgroundOpacity * 100).toInt()}%',
            ),
            const SizedBox(height: 4),
            _buildSlider(
              context: context,
              value: text.backgroundOpacity,
              min: 0.05,
              max: 1.0,
              divisions: 19,
              onChanged: (v) =>
                  store.updateCustomTextStyle(text.id, backgroundOpacity: v),
            ),
            const SizedBox(height: 8),
            _buildSectionLabel('BO GÓC  ${text.backgroundRadius.toInt()}px'),
            const SizedBox(height: 4),
            _buildSlider(
              context: context,
              value: text.backgroundRadius,
              min: 0,
              max: 40,
              divisions: 40,
              onChanged: (v) =>
                  store.updateCustomTextStyle(text.id, backgroundRadius: v),
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

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Colors.white38,
      ),
    );
  }

  Widget _buildSlider({
    required BuildContext context,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required void Function(double) onChanged,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: _accentColor,
        inactiveTrackColor: Colors.white12,
        thumbColor: Colors.white,
        overlayColor: _accentColor.withValues(alpha: 0.2),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? _accentColor : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildAlignButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? _accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.white70),
      ),
    );
  }

  Widget _buildColorPalette({
    required List<Color> colors,
    required Color? selectedColor,
    required void Function(Color) onSelect,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: colors.map((c) {
        final isSelected =
            selectedColor != null && selectedColor.toARGB32() == c.toARGB32();
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _accentColor : Colors.white24,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _accentColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
