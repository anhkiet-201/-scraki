import 'package:flutter/material.dart';

class EmailDataTextController extends TextEditingController {
  String? _lastText;
  TextSpan? _cachedFinalSpan;

  // Harmonious & Vibrant Colors for segments
  static const List<Color> _segmentColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF2DD4BF), // Teal
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Violet
  ];

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // 1. Fast Cache check
    if (_lastText == text && _cachedFinalSpan != null) {
      return _cachedFinalSpan!;
    }

    // 2. High Performance One-Pass Highlighting
    // Instead of splitting by lines (which allocates many strings), we use one regex
    // to find everything: Segments, Pipes, and Newlines.
    final List<TextSpan> spans = [];
    final matches = RegExp(r'([^|\n]+)|(\|)|(\n)').allMatches(text);
    
    int segmentIndex = 0;
    
    for (final match in matches) {
      if (match.group(3) != null) {
        // Newline: Reset segment index for the next line
        spans.add(const TextSpan(text: '\n'));
        segmentIndex = 0;
      } else if (match.group(2) != null) {
        // Pipe symbol
        spans.add(TextSpan(
          text: '|',
          style: style?.copyWith(
            color: Colors.grey.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
          ),
        ));
        segmentIndex++;
      } else if (match.group(1) != null) {
        // Text segment
        final color = _segmentColors[segmentIndex % _segmentColors.length];
        spans.add(TextSpan(
          text: match.group(1),
          style: style?.copyWith(color: color),
        ));
      }
    }

    _lastText = text;
    _cachedFinalSpan = TextSpan(style: style, children: spans);
    
    return _cachedFinalSpan!;
  }
}
