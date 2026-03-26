import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scraki/features/video_poster/presentation/widgets/form/time_input_field.dart';

/// Shared UI components for the property panels (Text, Image, etc.)
class PanelComponents {
  /// Common accent color for the video poster UI.
  static const Color kPanelAccentColor = Color(0xFF6366F1);

  static const List<Color> colorPalette = [
    Color(0xFFFFFFFF), // White
    Color(0xFF000000), // Black
    Color(0xFF6750A4), // M3 Primary
    Color(0xFFD0BCFF), // M3 Primary Light
    Color(0xFF625B71), // M3 Secondary
    Color(0xFFCCC2DC), // M3 Secondary Light
    Color(0xFF7D5260), // M3 Tertiary
    Color(0xFFEFB8C8), // M3 Tertiary Light
    Color(0xFFB3261E), // M3 Error (Red)
    Color(0xFFF2B8B5), // M3 Error Light
    Color(0xFF0061A4), // M3 Blue
    Color(0xFFD1E4FF), // M3 Blue Light
    Color(0xFF386A20), // M3 Green
    Color(0xFFC5EDB5), // M3 Green Light
  ];

  static const List<Color> darkColorPalette = [
    Color(0xFF000000), // Black
    Color(0xFF131313), // Deep Black
    Color(0xFF1C1B1F), // Dark Grey
    Color(0xFF2A2A2A), // Lighter Dark
    Color(0xFF410002), // Dark Red
    Color(0xFF072100), // Dark Green
    Color(0xFF001D36), // Dark Blue
    Color(0xFF331200), // Dark Orange
  ];

  static const List<Color> vibrantColorPalette = [
    Color(0xFFFFFFFF), // White
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Rose
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFFF97316), // Orange
    Color(0xFF84CC16), // Lime
  ];

  /// Builds a small, uppercase section label.
  static Widget buildSectionLabel(String label, {BuildContext? context}) {
    final isLight = context != null ? Theme.of(context).brightness == Brightness.light : false;
    return Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: isLight ? const Color(0xFF64748B) : Colors.white38, // Using Slate 500 for light mode
      ),
    );
  }

  /// Builds a stylized divider with text in the middle.
  static Widget buildPaletteDivider({BuildContext? context}) {
    final isLight = context != null ? Theme.of(context).brightness == Brightness.light : false;
    final dividerColor = isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.08);
    final textColor = isLight ? Colors.black26 : Colors.white24;

    return Row(
      children: [
        const Expanded(
          child: SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        Text(
          'OR',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: textColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: dividerColor,
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
    bool isReversed = false,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final thumbColor = isLight ? accentColor : Colors.white;
    final inactiveColor = isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white12;
    
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 7,
          elevation: 2,
          pressedElevation: 4,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: isReversed ? inactiveColor : accentColor,
        inactiveTrackColor: isReversed ? accentColor : inactiveColor,
        thumbColor: isLight ? Colors.white : thumbColor,
        overlayColor: accentColor.withValues(alpha: 0.15),
      ),
      child: SizedBox(
        height: 32,
        child: Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...colors.map((c) {
          final isSelected = selectedColor != null && selectedColor.toARGB32() == c.toARGB32();
          final borderColor = isSelected ? accentColor : Colors.transparent;
              
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
                  color: borderColor,
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
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
              border: Border.all(
                color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white12,
                width: 1,
              ),
              color: isLight ? Colors.black.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.03),
            ),
            child: Icon(
              Icons.colorize_rounded,
              size: 14,
              color: isLight ? const Color(0xFF94A3B8) : Colors.white60,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a horizontal wrap of recently used colors.
  static Widget buildRecentColors({
    required BuildContext context,
    required List<Color> colors,
    required Color? selectedColor,
    required void Function(Color) onSelect,
    Color accentColor = kPanelAccentColor,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final iconColor = isLight ? const Color(0xFF94A3B8) : Colors.white30;
    final textColor = isLight ? const Color(0xFF94A3B8) : Colors.white30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, size: 10, color: iconColor),
            const SizedBox(width: 4),
            Text(
              'GẦN ĐÂY',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: colors.take(7).map((c) {
            final isSelected = selectedColor != null && selectedColor.toARGB32() == c.toARGB32();
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
                    color: isSelected ? accentColor : Colors.transparent,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isLight ? Colors.white : const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.palette_rounded, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Text(
              'CHỌN MÀU',
              style: TextStyle(
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
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
                  hexInputBar: true,
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
                          child: Text(
                            'CŨ',
                            style: TextStyle(
                              fontSize: 9,
                              color: isLight ? Colors.black54 : Colors.white70,
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
                          child: Text(
                            'MỚI',
                            style: TextStyle(
                              fontSize: 9,
                              color: isLight ? Colors.black54 : Colors.white70,
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
            child: Text(
              'HỦY',
              style: TextStyle(
                color: isLight ? const Color(0xFF64748B) : Colors.white38,
              ),
            ),
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
    required BuildContext context,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    Color accentColor = kPanelAccentColor,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = active 
        ? accentColor.withValues(alpha: 0.15) 
        : (isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.04));
    final iconColor = active 
        ? accentColor 
        : (isLight ? const Color(0xFF64748B) : Colors.white38);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active && isLight
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }

  /// Builds a small alignment toggle button.
  static Widget buildAlignButton({
    required BuildContext context,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    Color accentColor = kPanelAccentColor,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final iconColor = active 
        ? accentColor 
        : (isLight ? const Color(0xFF94A3B8) : Colors.white24);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }

  /// Returns a safe font style, falling back to Roboto if the font family is not found.
  static TextStyle getSafeFont(
    String fontFamily, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? height,
    double? letterSpacing,
    List<ui.Shadow>? shadows,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    try {
      return GoogleFonts.getFont(
        fontFamily,
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        height: height,
        letterSpacing: letterSpacing,
        shadows: shadows,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
      );
    } catch (e) {
      debugPrint('Font $fontFamily not found, falling back to Roboto: $e');
      return GoogleFonts.roboto(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        height: height,
        letterSpacing: letterSpacing,
        shadows: shadows,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
      );
    }
  }

  /// List of supported font families.
  static const fontFamilies = <String>[
    // Modern Sans
    'Be Vietnam Pro',
    'Noto Sans',
    'Inter',
    'Roboto',
    'Coiny',

    // New Additions
    'Cherry Bomb One',
    'Potta One',
    'Vina Sans',
    'Sigmar One',
    'Bungee',
    'Bungee Shade',
    'Bungee Outline',
    'Grenze Gotisch',
    'Grenze',
    'Fruktur',
    'Tilt Prism',
    'Neonderthaw',
    'Big Shoulders Inline',
    'Major Mono Display',
    'Pacifico',
    'Borel',
    'Mynerve',
    'Shantell Sans',
    'Sedgwick Ave Display',
    'Sansita Swashed',
    'Gluten',
    'Festive',
  ];

  /// Builds a font picker dropdown.
  static Widget buildFontPicker({
    required BuildContext context,
    required String currentFont,
    required void Function(String) onFontSelected,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isLight 
            ? Colors.black.withValues(alpha: 0.03) 
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
          width: 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: fontFamilies.contains(currentFont) ? currentFont : 'Roboto',
          dropdownColor: isLight ? Colors.white : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          elevation: 8,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isLight ? const Color(0xFF64748B) : Colors.white38,
          ),
          isExpanded: true,
          style: TextStyle(
            color: isLight ? const Color(0xFF0F172A) : Colors.white, 
            fontSize: 13,
          ),
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
                style: getSafeFont(
                  font,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// A collapsible section for grouping properties.
  static Widget buildPanelSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    IconData? icon,
    bool initiallyExpanded = false,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = isLight 
        ? Colors.black.withValues(alpha: 0.02) 
        : Colors.white.withValues(alpha: 0.02);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        // Subtle border for light mode sections
        border: isLight ? Border.all(color: Colors.black.withValues(alpha: 0.02)) : null,
      ),
      child: Theme(
        data: (isLight ? ThemeData.light() : ThemeData.dark()).copyWith(
          dividerColor: Colors.transparent,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: icon != null 
              ? Icon(icon, size: 18, color: kPanelAccentColor.withValues(alpha: 0.8)) 
              : null,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: isLight ? const Color(0xFF1E293B) : Colors.white,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: kPanelAccentColor,
          collapsedIconColor: isLight ? const Color(0xFF94A3B8) : Colors.white30,
          children: children,
        ),
      ),
    );
  }

  /// A horizontal row for side-by-side controls.
  static Widget buildPanelRow({
    required List<Widget> children,
    double spacing = 12,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final widget = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: idx < children.length - 1 ? spacing : 0,
              ),
              child: widget,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Builds a time input field.
  static Widget buildTimeInput({
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
