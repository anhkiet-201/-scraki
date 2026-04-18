import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;
import 'package:flutter/material.dart';

class BrushBackgroundPainter extends CustomPainter {
  final Color color;
  final double intensity;
  final double thickness;
  final double complexity;

  BrushBackgroundPainter({
    required this.color,
    this.intensity = 2.0,
    this.thickness = 1.0,
    this.complexity = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    
    // Nới rộng vùng vẽ để các nét cọ có không gian "bay bổng"
    const paddingX = 30.0;
    const paddingY = 6.0;
    final rect = Rect.fromLTWH(
      -paddingX, 
      -paddingY, 
      size.width + paddingX * 2, 
      size.height + paddingY * 2
    );

    // 1. Độ cong và độ nghiêng tổng thể
    final globalCurve = (random.nextDouble() - 0.5) * 15.0; // Độ võng của nét cọ
    final globalTilt = (random.nextDouble() - 0.5) * 0.05;  // Độ nghiêng (radians)

    canvas.save();
    // Xoay nhẹ khung hình để tạo độ vát
    canvas.rotate(globalTilt);

    // 2. Vẽ các vệt cọ (Streaks) bằng đường cong
    final numStreaks = complexity.toInt().clamp(1, 40); // Sử dụng giá trị complexity động
    for (int i = 0; i < numStreaks; i++) {
        final streakOpacity = 0.2 + (random.nextDouble() * 0.8);
        final streakPaint = Paint()
          ..color = color.withValues(alpha: color.a * streakOpacity)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = (rect.height / (numStreaks / 1.5)) * (0.8 + random.nextDouble() * 0.5) * thickness;

        final path = Path();
        
        // Độ dài ngẫu nhiên mạnh để phá dáng vuông
        final startX = rect.left + (random.nextDouble() * 40.0);
        final endX = rect.right - (random.nextDouble() * 40.0);
        final yBase = rect.top + (rect.height / numStreaks) * i;
        
        path.moveTo(startX, yBase);
        
        // Vẽ đường cong Quadratic Bezier để tạo độ võng tự nhiên
        final controlX = (startX + endX) / 2;
        final controlY = yBase + globalCurve + (random.nextDouble() - 0.5) * 10.0;
        
        path.quadraticBezierTo(controlX, controlY, endX, yBase + (random.nextDouble() - 0.5) * 5.0);

        // Thêm một chút nhiễu cho đường cong (jitter)
        canvas.drawPath(_createJitteredPath(path, random, intensity: intensity), streakPaint);
    }

    // 3. Hiệu ứng lông cọ khô (Dry bristles) và vệt mực văng
    final bristlePaint = Paint()
      ..color = color.withValues(alpha: color.a * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 50; i++) {
      final y = rect.top + random.nextDouble() * rect.height;
      final isLeft = random.nextBool();
      final length = 10.0 + random.nextDouble() * 25.0;
      final xStart = isLeft ? rect.left : rect.right - length;
      final xOffset = (random.nextDouble() - 0.5) * 10.0;
      
      canvas.drawLine(
        Offset(xStart + xOffset, y),
        Offset(xStart + length + xOffset, y + (random.nextDouble() - 0.5) * 3.0),
        bristlePaint
      );
    }

    // 4. Thêm các vết đốm mực nhỏ (Splats) để trông "thật" hơn
    final splatPaint = Paint()
      ..color = color.withValues(alpha: color.a * 0.3)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 15; i++) {
      final x = rect.left + random.nextDouble() * rect.width;
      final y = rect.top + random.nextDouble() * rect.height;
      final r = 0.5 + random.nextDouble() * 2.0;
      canvas.drawCircle(Offset(x, y), r, splatPaint);
    }

    canvas.restore();
  }

  Path _createJitteredPath(Path source, math.Random random, {double intensity = 2.0}) {
    final Path jitteredPath = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      final double length = metric.length;
      final int segments = (length / 5.0).clamp(2, 200).toInt();
      
      bool first = true;
      for (int i = 0; i <= segments; i++) {
        final double t = i / segments;
        final Tangent? tangent = metric.getTangentForOffset(length * t);
        if (tangent != null) {
          final Offset normal = Offset(-tangent.vector.dy, tangent.vector.dx);
          final double jitter = (random.nextDouble() - 0.5) * intensity;
          final Offset point = tangent.position + normal * jitter;
          
          if (first) {
            jitteredPath.moveTo(point.dx, point.dy);
            first = false;
          } else {
            jitteredPath.lineTo(point.dx, point.dy);
          }
        }
      }
    }
    return jitteredPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
