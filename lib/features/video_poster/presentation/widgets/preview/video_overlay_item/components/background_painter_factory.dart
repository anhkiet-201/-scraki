import 'package:flutter/material.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';
import 'painters/paper_painter.dart';
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
  }) {
    final bgColor = color.withValues(alpha: color.a * opacity);

    switch (style) {
      case TextBackgroundStyle.rectangle:
        return null;
        
      case TextBackgroundStyle.glass:
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
    }
  }
}
