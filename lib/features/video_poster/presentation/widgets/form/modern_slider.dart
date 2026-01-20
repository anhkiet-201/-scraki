import 'package:flutter/material.dart';

/// Reusable modern-styled slider component
///
/// Features:
/// - Consistent styling
/// - Value display with suffix and multiplier
/// - Enable/disable support
/// - Custom min/max ranges
class ModernSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String suffix;
  final double multiplier;
  final bool enabled;

  const ModernSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix = "",
    this.multiplier = 1.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: enabled ? Colors.white70 : Colors.white24,
              ),
            ),
            Text(
              "${(value * multiplier).toStringAsFixed(multiplier == 100 ? 0 : 1)}$suffix",
              style: TextStyle(
                fontSize: 11,
                color: enabled ? const Color(0xFF6366F1) : Colors.white24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: enabled
                ? const Color(0xFF6366F1)
                : Colors.white10,
            inactiveTrackColor: Colors.white10,
            thumbColor: enabled ? Colors.white : Colors.white12,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}
