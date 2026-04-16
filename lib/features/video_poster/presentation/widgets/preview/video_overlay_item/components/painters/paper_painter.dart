import 'dart:math' as math;
import 'package:flutter/material.dart';

class OrganicPaperPainter extends CustomPainter {
  final Color color;
  final double roughness;

  OrganicPaperPainter({
    required this.color,
    required this.roughness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;

    final path = Path();
    final random = math.Random(42); // Seeded for consistency

    void drawRoughLine(Offset start, Offset end) {
      final dist = (end - start).distance;
      // Chia nhỏ đoạn thẳng thành nhiều phần hơn để đường xé chi tiết
      final steps = (dist / 5).toDouble().clamp(10.0, 100.0).toInt();
      
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        final lerped = Offset.lerp(start, end, t)!;
        if (i == 0) continue;
        
        // Tạo nhiễu đa tầng (kết hợp các tần số khác nhau để trông tự nhiên hơn)
        final noise1 = (random.nextDouble() - 0.5) * roughness * 5;
        final noise2 = (random.nextDouble() - 0.5) * roughness * 2;
        final jitter = noise1 + noise2;
        
        final normal = Offset(-(end.dy - start.dy), end.dx - start.dx).unit * jitter;
        path.lineTo(lerped.dx + normal.dx, lerped.dy + normal.dy);
      }
    }

    path.moveTo(0, 0);
    drawRoughLine(const Offset(0, 0), Offset(size.width, 0));
    drawRoughLine(Offset(size.width, 0), Offset(size.width, size.height));
    drawRoughLine(Offset(size.width, size.height), Offset(0, size.height));
    drawRoughLine(Offset(0, size.height), const Offset(0, 0));
    path.close();

    // 1. Draw Organic Shadow (Đa tầng để có chiều sâu thực tế)
    canvas.drawPath(
      path.shift(const Offset(3, 4)), 
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
    );

    // 2. Draw Clear White Fiber Highlights (Xơ giấy rõ nét hơn)
    final fiberPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path.shift(const Offset(-1.5, -1.5)), fiberPaint);
    
    // 3. Draw Main Paper
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, mainPaint);

    // Thêm vân giấy/sợi gỗ bên trong để trông tự nhiên hơn
    _drawInternalTexture(canvas, size, color, random);

    // 4. Draw Micro-Fibers (Vẽ thêm các sợi giấy li ti ngẫu nhiên ở viền)
    final fiberStrokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Tái cấu trúc lại một chút để lấy các điểm trên path vẽ xơ giấy
    for (int i = 0; i < 20; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        // Chỉ vẽ gần mép (đơn giản hóa bằng cách check cạnh)
        if (x < 5 || x > size.width - 5 || y < 5 || y > size.height - 5) {
            canvas.drawLine(
                Offset(x, y), 
                Offset(x + (random.nextDouble()-0.5)*4, y + (random.nextDouble()-0.5)*4), 
                fiberStrokePaint
            );
        }
    }
  }

  void _drawInternalTexture(Canvas canvas, Size size, Color baseColor, math.Random random) {
    // Sử dụng layer riêng để áp dụng clipping dễ dàng hơn nếu cần, 
    // ở đây ta vẽ trực tiếp và dùng logic clip đơn giản
    
    // 1. Vẽ các đường vân chính (Grain Lines)
    _drawGrainLines(canvas, size, random);
    
    // 2. Vẽ các mắt gỗ (Knots) - Rất mờ
    _drawKnots(canvas, size, random);
    
    // 3. Vẽ các đốm bột giấy (Speckles)
    _drawSpeckles(canvas, size, random);
  }

  void _drawGrainLines(Canvas canvas, Size size, math.Random random) {
    final grainPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    
    // Vẽ các đường vân dài chạy dọc theo chiều ngang với độ lượn sóng
    final rowCount = (size.height / 8).toInt();
    for (int i = 0; i < rowCount; i++) {
        final yBase = i * 8.0;
        final path = Path();
        path.moveTo(0, yBase + (random.nextDouble() - 0.5) * 10);
        
        final steps = 5;
        final stepWidth = size.width / steps;
        
        for (int j = 1; j <= steps; j++) {
            final x = j * stepWidth;
            final y = yBase + (random.nextDouble() - 0.5) * 15;
            path.quadraticBezierTo(
                x - stepWidth/2, yBase + (random.nextDouble() - 0.5) * 20,
                x, y
            );
        }
        canvas.drawPath(path, grainPaint);
    }
  }

  void _drawKnots(Canvas canvas, Size size, math.Random random) {
    final knotPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
      
    for (int i = 0; i < 2; i++) {
        final cx = random.nextDouble() * size.width;
        final cy = random.nextDouble() * size.height;
        
        // Vẽ các vòng tròn đồng tâm méo mó để tạo mắt gỗ
        for (int r = 1; r < 4; r++) {
            canvas.drawOval(
                Rect.fromCenter(center: Offset(cx, cy), width: r * 15.0, height: r * 8.0),
                knotPaint
            );
        }
    }
  }

  void _drawSpeckles(Canvas canvas, Size size, math.Random random) {
    final specklePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 40; i++) {
      final pos = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      final r = random.nextDouble() * 1.2 + 0.3;
      specklePaint.color = Colors.black.withValues(alpha: random.nextDouble() * 0.06);
      canvas.drawCircle(pos, r, specklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant OrganicPaperPainter oldDelegate) => 
      oldDelegate.color != color || oldDelegate.roughness != roughness;
}

extension on Offset {
  Offset get unit => distance == 0 ? Offset.zero : this / distance;
}