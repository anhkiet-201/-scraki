import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scraki/features/video_poster/presentation/widgets/form/time_input_field.dart';

/// Shared UI components for the property panels (Text, Image, etc.)
class PanelComponents {
  /// Common accent color for the video poster UI.
  static const Color kPanelAccentColor = Color(0xFF6366F1);

  static const List<Color> colorPalette = [
    Color(0xFFFFFFFF),
    Color(0xFFE6E1E5),
    Color(0xFF938F99),
    Color(0xFF1C1B1F),
    Color(0xFF6750A4),
    Color(0xFF9A82DB),
    Color(0xFFCFBCFF),
    Color(0xFFEADDFF),
    Color(0xFF625B71),
    Color(0xFF9A91A8),
    Color(0xFFCCC2DC),
    Color(0xFFE8DEF8),
    Color(0xFF7D5260),
    Color(0xFFB58392),
    Color(0xFFEFB8C8),
    Color(0xFFFFD8E4),
    Color(0xFFB3261E),
    Color(0xFFEC928E),
    Color(0xFFF2B8B5),
    Color(0xFF386A20),
    Color(0xFF57A640),
    Color(0xFF8FC877),
    Color(0xFFC5EDB5),
    Color(0xFF0061A4),
    Color(0xFF4FA6E7),
    Color(0xFF9ECAFF),
    Color(0xFFD0E4FF),
    Color(0xFF695F00),
    Color(0xFFD2C148),
    Color(0xFFEFE06D),
    Color(0xFF984900),
    Color(0xFFD66600),
    Color(0xFFFFB68E),
    Color(0xFFFFDDB3),
    Color(0xFF006A6A),
    Color(0xFF008383),
    Color(0xFF4DDEDE),
    Color(0xFFBFFFFF),
    Color(0xFF5F4ABB),
    Color(0xFF8069DF),
    Color(0xFFC6B0FF),
    Color(0xFFE6DEFF),
  ];

  static const List<Color> darkColorPalette = [
    Color(0xFF000000), // Black
    Color(0xFF1C1B1F), // Dark Grey
    Color(0xFF2A2A2A), // Darker Grey
    // Red dark
    Color(0xFF410002), // Error-6
    Color(0xFF690005), // Error-20
    Color(0xFF93000A), // Error-30
    // Green dark
    Color(0xFF072100), // Green-6
    Color(0xFF1A3D07), // Green-20
    // Blue dark
    Color(0xFF001D36), // Blue-6
    Color(0xFF003258), // Blue-20
    // Orange dark
    Color(0xFF331200), // Orange-10
    Color(0xFF4D1C00), // Orange-20
    // Teal dark
    Color(0xFF002020), // Teal-10
    Color(0xFF003737), // Teal-20
    // Deep Purple dark
    Color(0xFF1B0062), // Deep Purple-10
    Color(0xFF2F1581), // Deep Purple-20
  ];

  /// Builds a small, uppercase section label.
  static Widget buildSectionLabel(String label) {
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

  /// Builds a stylized divider with text in the middle.
  static Widget buildPaletteDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'OR',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.white24,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ],
    );
  }

  /// Builds a customized slider with specific theme.
  static Widget buildSlider({
    required BuildContext context,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required void Function(double) onChanged,
    Color accentColor = kPanelAccentColor,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: accentColor,
        inactiveTrackColor: Colors.white12,
        thumbColor: Colors.white,
        overlayColor: accentColor.withOpacity(0.2),
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

  /// Builds a horizontal wrap of colors with selection indicator.
  static Widget buildColorPalette({
    required BuildContext context,
    required List<Color> colors,
    required Color? selectedColor,
    required void Function(Color) onSelect,
    required VoidCallback onPickCustom,
    Color accentColor = kPanelAccentColor,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...colors.map((c) {
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
                  color: isSelected ? accentColor : Colors.white24,
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
        // Custom color picker button
        GestureDetector(
          onTap: onPickCustom,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
              color: Colors.white.withOpacity(0.05),
            ),
            child: const Icon(
              Icons.colorize_rounded,
              size: 14,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a horizontal wrap of recently used colors.
  static Widget buildRecentColors({
    required List<Color> colors,
    required Color? selectedColor,
    required void Function(Color) onSelect,
    Color accentColor = kPanelAccentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_rounded, size: 10, color: Colors.white30),
            SizedBox(width: 4),
            Text(
              'GẦN ĐÂY',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.white30,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: colors.map((c) {
            final isSelected =
                selectedColor != null &&
                selectedColor.toARGB32() == c.toARGB32();
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
                    color: isSelected ? accentColor : Colors.white38,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Shows a color picker dialog.
  static Future<void> showColorPicker({
    required BuildContext context,
    required Color initialColor,
    required void Function(Color) onColorSelected,
    Color accentColor = kPanelAccentColor,
  }) async {
    Color pickedColor = initialColor;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.palette_rounded, size: 18, color: accentColor),
            const SizedBox(width: 8),
            const Text(
              'CHỌN MÀU',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (_, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPicker(
                  pickerColor: pickedColor,
                  onColorChanged: (Color color) {
                    setState(() => pickedColor = color);
                  },
                  colorPickerWidth: 280,
                  pickerAreaHeightPercent: 0.7,
                  enableAlpha: true,
                  labelTypes: const [ColorLabelType.hex, ColorLabelType.hsv],
                  displayThumbColor: true,
                  pickerAreaBorderRadius: const BorderRadius.all(
                    Radius.circular(12),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 32,
                          color: initialColor,
                          alignment: Alignment.center,
                          child: const Text(
                            'CŨ',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 32,
                          color: pickedColor,
                          alignment: Alignment.center,
                          child: const Text(
                            'MỚI',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('HỦY', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              onColorSelected(pickedColor);
              Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'CHỌN',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a toggle button (e.g., Bold, Italic).
  static Widget buildToggleButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    Color accentColor = kPanelAccentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? accentColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? accentColor : Colors.white10,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? accentColor : Colors.white38,
        ),
      ),
    );
  }

  /// Builds a small alignment toggle button.
  static Widget buildAlignButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    Color accentColor = kPanelAccentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? accentColor : Colors.white24,
        ),
      ),
    );
  }

  /// List of supported font families.
  static const fontFamilies = <String>[
    'Be Vietnam Pro',
    'Noto Sans',
    'Inter',
    'Roboto',
    'Nunito',
    'Lato',
    'Source Sans 3',
    'Open Sans',
    'Barlow',
    'DM Sans',
    'Lexend',
    'Merriweather',
    'Playfair Display',
    'Lora',
    'Noto Serif',
    'Montserrat',
    'Oswald',
    'Raleway',
    'Barlow Condensed',
    'Exo 2',
    'Kanit',
    'Quicksand',
    'Comfortaa',
    'Righteous',
    'Cabin',
    'Dancing Script',
    'Pacifico',
    'Satisfy',
    'Lobster',
  ];

  /// Builds a font picker dropdown.
  static Widget buildFontPicker({
    required String currentFont,
    required void Function(String) onFontSelected,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: fontFamilies.contains(currentFont) ? currentFont : 'Roboto',
          dropdownColor: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white38,
          ),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onFontSelected(newValue);
            }
          },
          items: fontFamilies.map<DropdownMenuItem<String>>((String font) {
            return DropdownMenuItem<String>(
              value: font,
              child: Text(
                font,
                style: GoogleFonts.getFont(
                  font,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Builds a time input field.
  static Widget buildTimeInput({
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
