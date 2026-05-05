import 'package:flutter/material.dart';

class QuoteBackgroundPainter extends CustomPainter {
  final Color color;
  final double barWidth;
  final double bgOpacityFactor;

  QuoteBackgroundPainter({
    required this.color,
    this.barWidth = 4.0,
    this.bgOpacityFactor = 0.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;

    // 1. Draw subtle background (custom opacity factor of the main color)
    final bgPaint = Paint()
      ..color = color.withValues(alpha: color.a * bgOpacityFactor)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Draw solid vertical bar on the left
    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final barRect = Rect.fromLTRB(0, 0, barWidth, size.height);
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant QuoteBackgroundPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.barWidth != barWidth ||
           oldDelegate.bgOpacityFactor != bgOpacityFactor;
  }
}
