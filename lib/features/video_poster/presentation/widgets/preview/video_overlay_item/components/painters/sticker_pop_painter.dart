import 'package:flutter/material.dart';

class StickerPopBackgroundPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final Color backingColor;
  final Color accentColor; // Lớp chữ vàng
  final Color shadowColor; // Lớp bóng đen
  final double offset;     // Độ lệch 3D
  final double padding;    // Độ dày đế sticker
  final double radius;     // Độ bo góc nền

  StickerPopBackgroundPainter({
    required this.text,
    required this.textStyle,
    required this.textAlign,
    required this.backingColor,
    required this.accentColor,
    required this.shadowColor,
    required this.offset,
    required this.padding,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: size.width);

    // 1. Tạo Path hợp nhất các khối bao quanh chữ để làm đế Sticker
    final path = Path();
    final textBoxes = textPainter.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    );

    for (final box in textBoxes) {
      // Mở rộng vùng bao theo padding và bo tròn
      final rect = box.toRect().inflate(padding);
      path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    }

    // 2. Vẽ Đế Sticker (Lớp dưới cùng)
    final backingPaint = Paint()
      ..color = backingColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, backingPaint);

    // 3. Vẽ Bóng đổ chữ (Lớp màu đen) - Offset sâu nhất
    // Sử dụng TextPainter để vẽ chữ bản sao phía sau
    final shadowOffset = Offset(offset * 1.3, offset * 1.3);
    canvas.save();
    canvas.translate(shadowOffset.dx, shadowOffset.dy);
    textPainter.text = TextSpan(
      text: text, 
      style: textStyle.copyWith(
        color: shadowColor, 
        foreground: null,
      ),
    );
    textPainter.layout(maxWidth: size.width);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    // 4. Vẽ Chữ 3D (Lớp màu vàng) - Offset trung bình
    final accentOffset = Offset(offset, offset);
    canvas.save();
    canvas.translate(accentOffset.dx, accentOffset.dy);
    textPainter.text = TextSpan(
      text: text, 
      style: textStyle.copyWith(
        color: accentColor, 
        foreground: null,
      ),
    );
    textPainter.layout(maxWidth: size.width);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StickerPopBackgroundPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.textAlign != textAlign ||
        oldDelegate.backingColor != backingColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.offset != offset ||
        oldDelegate.padding != padding ||
        oldDelegate.radius != radius;
  }
}
