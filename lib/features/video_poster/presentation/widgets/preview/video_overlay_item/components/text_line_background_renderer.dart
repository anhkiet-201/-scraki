import 'package:flutter/material.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart' show TextBackgroundStyle;
import 'background_painter_factory.dart';

class TextWithLineBackgrounds extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final Color backgroundColor;
  final TextBackgroundStyle backgroundStyle;
  final double backgroundOpacity;
  final double backgroundRadius;
  final Color? backgroundBorderColor;
  final double backgroundBorderWidth;
  final Color? strokeColor;
  final double strokeWidth;
  final double brushIntensity;
  final double brushThickness;
  final double brushComplexity;
  final double backgroundPadding;
  final Map<String, dynamic> styleParams;

  const TextWithLineBackgrounds({
    super.key,
    required this.text,
    required this.style,
    required this.textAlign,
    required this.backgroundColor,
    this.backgroundStyle = TextBackgroundStyle.rectangle,
    required this.backgroundOpacity,
    required this.backgroundRadius,
    this.backgroundBorderColor,
    this.backgroundBorderWidth = 0.0,
    this.strokeColor,
    this.strokeWidth = 0.0,
    this.brushIntensity = 2.0,
    this.brushThickness = 1.0,
    this.brushComplexity = 12.0,
    this.backgroundPadding = 20.0,
    this.styleParams = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (backgroundStyle == TextBackgroundStyle.highlight) {
      return _buildHighlightRichText(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final lineTexts = _computeLineTexts(constraints.maxWidth);
        if (lineTexts.isEmpty) return const SizedBox.shrink();

        final bgColor = backgroundColor.withValues(alpha: backgroundOpacity);
        final crossAxis = switch (textAlign) {
          TextAlign.left || TextAlign.start => CrossAxisAlignment.start,
          TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
          _ => CrossAxisAlignment.center,
        };

        // Chuẩn hóa TextStyle để tránh sai lệch metrics trên các nền tảng (đặc biệt là Windows)
        final normalizedStyle = style.copyWith(
          // Chiều cao dòng tường minh giúp ổn định kích thước container giữa các OS
          height: style.height ?? 1.1, 
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxis,
          children: [
            for (int i = 0; i < lineTexts.length; i++)
              _buildSingleLine(
                lineText: lineTexts[i], 
                bgColor: bgColor, 
                isFirst: i == 0,
                style: normalizedStyle,
              ),
          ],
        );
      },
    );
  }

  /// Xây dựng một dòng duy nhất bao gồm cả Nền và Chữ trong cùng một Stack (Atomic Layout).
  /// Việc này đảm bảo chữ luôn căn chỉnh chính xác theo nền của chính nó, 
  /// loại bỏ lỗi tích lũy sai số metrics khi dùng 2 cột riêng biệt.
  Widget _buildSingleLine({
    required String lineText, 
    required Color bgColor, 
    required bool isFirst,
    required TextStyle style,
  }) {
    // 1. Khởi tạo Painter cho nền
    final painter = BackgroundPainterFactory.create(
      style: backgroundStyle,
      color: backgroundColor,
      opacity: backgroundOpacity,
      params: styleParams,
      radius: backgroundRadius,
      brushIntensity: brushIntensity,
      brushThickness: brushThickness,
      brushComplexity: brushComplexity,
      text: lineText,
      textStyle: style,
      textAlign: textAlign,
      backgroundPadding: backgroundPadding,
    );

    final decoration = backgroundStyle == TextBackgroundStyle.rectangle 
        ? BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(backgroundRadius),
            border: backgroundBorderWidth > 0 && backgroundBorderColor != null
                ? Border.all(color: backgroundBorderColor!, width: backgroundBorderWidth)
                : null,
          )
        : null;

    // Common padding and margin for both layers to ensure perfect overlap
    final margin = EdgeInsets.only(top: isFirst ? 0 : 4);
    final padding = EdgeInsets.symmetric(horizontal: backgroundPadding, vertical: 4);

    return Container(
      margin: margin,
      child: Stack(
        // Alignment center để đảm bảo dù có sai lệch metrics, chữ vẫn nằm giữa nền
        alignment: Alignment.center,
        children: [
          // Layer 1: Background (CustomPaint)
          CustomPaint(
            painter: painter,
            child: Container(
              padding: padding,
              decoration: decoration,
              // Dùng text ẩn để đo kích thước nền khớp hoàn toàn với text thật
              child: Opacity(
                opacity: 0,
                child: Text(
                  lineText, 
                  style: style, 
                  maxLines: 1, 
                  softWrap: false,
                  textAlign: textAlign,
                ),
              ),
            ),
          ),

          // Layer 2: Text (Stroke + Fill)
          Container(
            padding: padding,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (strokeColor != null && strokeWidth > 0)
                  Text(
                    lineText,
                    style: style.copyWith(
                      color: null,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeJoin = StrokeJoin.round
                        ..strokeCap = StrokeCap.round
                        ..strokeWidth = strokeWidth
                        ..color = strokeColor!,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    textAlign: textAlign,
                  ),
                Text(
                  lineText,
                  style: style,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: textAlign,
                  // Chuẩn hóa cách Flutter xử lý chiều cao ký tự để đồng nhất giữa Windows/macOS
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: true,
                    applyHeightToLastDescent: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, List<HighlightRange>) _extractHighlights(String rawText) {
    final regex = RegExp(r'\*{1,2}([^\*]+)\*{1,2}');
    final ranges = <HighlightRange>[];
    final buffer = StringBuffer();
    int lastMatchEnd = 0;
    
    for (final match in regex.allMatches(rawText)) {
      if (match.start > lastMatchEnd) {
        buffer.write(rawText.substring(lastMatchEnd, match.start));
      }
      final highlightStart = buffer.length;
      final highlightText = match.group(1)!;
      buffer.write(highlightText);
      final highlightEnd = buffer.length;
      ranges.add(HighlightRange(highlightStart, highlightEnd));
      
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < rawText.length) {
      buffer.write(rawText.substring(lastMatchEnd));
    }
    
    return (buffer.toString(), ranges);
  }

  Widget _buildHighlightRichText(BuildContext context) {
    final bgColor = backgroundColor.withValues(alpha: backgroundOpacity);
    final normalizedStyle = style.copyWith(height: style.height ?? 1.1);

    final (cleanText, ranges) = _extractHighlights(text);
    
    final baseSpan = TextSpan(text: cleanText, style: normalizedStyle);
    final strokeSpan = (strokeColor != null && strokeWidth > 0) 
        ? TextSpan(
            text: cleanText,
            style: normalizedStyle.copyWith(
              color: null,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeJoin = StrokeJoin.round
                ..strokeCap = StrokeCap.round
                ..strokeWidth = strokeWidth
                ..color = strokeColor!,
            ),
          )
        : null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: backgroundPadding, vertical: 4),
      child: CustomPaint(
        painter: HighlightInlinePainter(
          textSpan: baseSpan,
          textAlign: textAlign,
          ranges: ranges,
          color: bgColor,
          padding: backgroundPadding,
          radius: backgroundRadius,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (strokeSpan != null)
              Text.rich(
                strokeSpan,
                textAlign: textAlign,
                softWrap: true,
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: true,
                  applyHeightToLastDescent: true,
                ),
              ),
            Text.rich(
              baseSpan,
              textAlign: textAlign,
              softWrap: true,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: true,
                applyHeightToLastDescent: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tách text thành danh sách text từng dòng dựa trên cách TextPainter wrap.
  List<String> _computeLineTexts(double maxWidth) {
    if (text.isEmpty) return [];

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final lines = painter.computeLineMetrics();
    if (lines.isEmpty) return [text];

    final result = <String>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.width == 0 && i == lines.length - 1) {
        continue; // bỏ qua dòng cuối rỗng
      }

      final midY = line.baseline - line.ascent * 0.5;
      final startPos = painter
          .getPositionForOffset(Offset(line.left + 0.1, midY))
          .offset;

      final int endPos;
      if (i + 1 < lines.length) {
        final nextLine = lines[i + 1];
        final nextMidY = nextLine.baseline - nextLine.ascent * 0.5;
        endPos = painter
            .getPositionForOffset(Offset(nextLine.left + 0.1, nextMidY))
            .offset;
      } else {
        endPos = text.length;
      }

      final lineText = text
          .substring(startPos, endPos.clamp(startPos, text.length))
          .trimRight();
      if (lineText.isNotEmpty) result.add(lineText);
    }

    return result.isEmpty ? [text] : result;
  }
}

class HighlightRange {
  final int start;
  final int end;
  HighlightRange(this.start, this.end);
}

class HighlightInlinePainter extends CustomPainter {
  final TextSpan textSpan;
  final TextAlign textAlign;
  final List<HighlightRange> ranges;
  final Color color;
  final double padding;
  final double radius;

  HighlightInlinePainter({
    required this.textSpan,
    required this.textAlign,
    required this.ranges,
    required this.color,
    required this.padding,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0 || ranges.isEmpty) return;

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: true,
        applyHeightToLastDescent: true,
      ),
    );

    textPainter.layout(maxWidth: size.width);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    for (final range in ranges) {
      final boxes = textPainter.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      );

      for (final box in boxes) {
        final rect = Rect.fromLTRB(
          box.left - padding,
          box.top - 2.0, 
          box.right + padding,
          box.bottom + 2.0,
        );
        path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HighlightInlinePainter oldDelegate) {
    return oldDelegate.textSpan != textSpan ||
           oldDelegate.textAlign != textAlign ||
           oldDelegate.color != color ||
           oldDelegate.padding != padding ||
           oldDelegate.radius != radius;
  }
}

