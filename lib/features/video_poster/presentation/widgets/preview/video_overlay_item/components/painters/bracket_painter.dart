import 'package:flutter/material.dart';

class BracketBackgroundPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double length;

  BracketBackgroundPainter({
    required this.color,
    this.thickness = 2.0,
    this.length = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final rect = Offset.zero & size;
    final path = Path();

    // Top-Left corner
    path.moveTo(rect.left, rect.top + length);
    path.lineTo(rect.left, rect.top);
    path.lineTo(rect.left + length, rect.top);

    // Top-Right corner
    path.moveTo(rect.right - length, rect.top);
    path.lineTo(rect.right, rect.top);
    path.lineTo(rect.right, rect.top + length);

    // Bottom-Left corner
    path.moveTo(rect.left, rect.bottom - length);
    path.lineTo(rect.left, rect.bottom);
    path.lineTo(rect.left + length, rect.bottom);

    // Bottom-Right corner
    path.moveTo(rect.right - length, rect.bottom);
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.right, rect.bottom - length);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BracketBackgroundPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.length != length;
  }
}
