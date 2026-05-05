import 'package:flutter/material.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'painters/paper_painter.dart';
import 'painters/bracket_painter.dart';
import 'painters/quote_painter.dart';
import 'painters/sticker_pop_painter.dart';
import 'brush_background_painter.dart';
class BackgroundPainterFactory {
  static CustomPainter? create({
    required TextBackgroundStyle style,
    required Color color,
    required double opacity,
    required Map<String, dynamic> params,
    double radius = 8.0,
    // Keep legacy brush params for compatibility
    double brushIntensity = 2.0,
    double brushThickness = 1.0,
    double brushComplexity = 12.0,
    String text = '',
    TextStyle? textStyle,
    TextAlign textAlign = TextAlign.center,
    double backgroundPadding = 20.0,
  }) {
    final bgColor = color.withValues(alpha: color.a * opacity);

    switch (style) {
      case TextBackgroundStyle.rectangle:
        return null;
        
      case TextBackgroundStyle.brush:
        return BrushBackgroundPainter(
          color: bgColor,
          intensity: brushIntensity,
          thickness: brushThickness,
          complexity: brushComplexity,
        );
        
      case TextBackgroundStyle.paper:
        return OrganicPaperPainter(
          color: bgColor,
          roughness: (params['paper_roughness'] as num?)?.toDouble() ?? 1.5,
        );

      case TextBackgroundStyle.bracket:
        return BracketBackgroundPainter(
          color: bgColor,
          thickness: (params['bracket_thickness'] as num?)?.toDouble() ?? 2.0,
          length: (params['bracket_length'] as num?)?.toDouble() ?? 12.0,
        );

      case TextBackgroundStyle.highlight:
        return null;

      case TextBackgroundStyle.quote:
        return QuoteBackgroundPainter(
          color: bgColor,
          barWidth: (params['quote_bar_width'] as num?)?.toDouble() ?? 4.0,
          bgOpacityFactor: (params['quote_bg_opacity'] as num?)?.toDouble() ?? 0.2,
        );

      case TextBackgroundStyle.stickerPop:
        return StickerPopBackgroundPainter(
          text: text,
          textStyle: textStyle ?? const TextStyle(),
          textAlign: textAlign,
          backingColor: bgColor,
          accentColor: Color((params['sticker_3d_color'] as int?) ?? 0xFFFFC107), // Amber
          shadowColor: Color((params['sticker_shadow_color'] as int?) ?? 0xFF000000), // Black
          offset: (params['sticker_offset'] as num?)?.toDouble() ?? 6.0,
          padding: backgroundPadding,
          radius: radius,
        );
    }
  }
}
