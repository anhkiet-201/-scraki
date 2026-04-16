import 'package:flutter/material.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart' show TextBackgroundStyle;
import 'brush_background_painter.dart';

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
  });

  @override
  Widget build(BuildContext context) {
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

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxis,
          children: [
            for (int i = 0; i < lineTexts.length; i++)
              Container(
                margin: EdgeInsets.only(top: i == 0 ? 0 : 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                decoration: backgroundStyle == TextBackgroundStyle.rectangle 
                    ? BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(backgroundRadius),
                        border:
                            backgroundBorderWidth > 0 && backgroundBorderColor != null
                            ? Border.all(
                                color: backgroundBorderColor!,
                                width: backgroundBorderWidth,
                              )
                            : null,
                      )
                    : null,
                child: CustomPaint(
                  painter: backgroundStyle == TextBackgroundStyle.brush 
                      ? BrushBackgroundPainter(
                          color: bgColor,
                          intensity: brushIntensity,
                          thickness: brushThickness,
                          complexity: brushComplexity,
                        )
                      : null,
                  child: Stack(
                    children: [
                      if (strokeColor != null && strokeWidth > 0)
                        Text(
                          lineTexts[i],
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
                        lineTexts[i],
                        style: style,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: textAlign,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
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

      // Lấy vị trí character bằng cách probe giữa dòng
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
