import 'package:flutter/material.dart';

class EmailDataTextController extends TextEditingController {
  // Line-level cache: line content hash -> TextSpan
  final Map<int, TextSpan> _lineCache = {};
  String? _lastText;
  TextSpan? _cachedFinalSpan;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_lastText == text && _cachedFinalSpan != null) {
      return _cachedFinalSpan!;
    }

    final List<String> lines = text.split('\n');
    final List<TextSpan> lineSpans = [];

    // Harmonious Colors for IDE segments
    final List<Color> segmentColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald 
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFD946EF), // Fuchsia
    ];

    for (int i = 0; i < lines.length; i++) {
      final String lineText = lines[i];
      final int lineHash = lineText.hashCode;

      // Check cache for this specific line
      TextSpan? lineSpan = _lineCache[lineHash];
      
      if (lineSpan == null) {
        final List<TextSpan> segments = [];
        final matches = RegExp(r'([^|]+)|(\|)').allMatches(lineText);
        
        int segmentIndex = 0; // Reset for each line for consistency
        
        for (final match in matches) {
          if (match.group(2) != null) {
            // Pipe symbol
            segments.add(TextSpan(
              text: '|',
              style: style?.copyWith(
                color: Colors.grey.withValues(alpha: 0.3),
                fontWeight: FontWeight.bold,
              ),
            ));
            segmentIndex++;
          } else {
            // Text segment
            final color = segmentColors[segmentIndex % segmentColors.length];
            segments.add(TextSpan(
              text: match.group(0),
              style: style?.copyWith(color: color),
            ));
          }
        }
        
        lineSpan = TextSpan(children: segments);
        _lineCache[lineHash] = lineSpan;
      }

      lineSpans.add(lineSpan);
      
      // Add newline character between lines, except after the last one
      if (i < lines.length - 1) {
        lineSpans.add(const TextSpan(text: '\n'));
      }
    }

    _lastText = text;
    _cachedFinalSpan = TextSpan(style: style, children: lineSpans);
    
    // Cleanup cache periodically to avoid memory creep
    if (_lineCache.length > 20000) {
      _lineCache.clear();
    }
    
    return _cachedFinalSpan!;
  }
}
