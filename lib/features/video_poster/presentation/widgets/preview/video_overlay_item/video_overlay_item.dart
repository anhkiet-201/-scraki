import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'video_overlay_item_store.dart';

/// Draggable and interactive text overlay item for video preview.
/// Fully self-contained — no dependency on any global store.
class VideoOverlayItem extends StatefulWidget {
  final String label;
  final double x;
  final double y;
  final String type;
  final BoxConstraints constraints;
  final Color color;
  final double fontSize;
  final double? textHeight;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final TextAlign textAlign;
  final Color? backgroundColor;
  final double backgroundOpacity;
  final double backgroundRadius;
  final bool isSelected;
  final void Function(String type, double x, double y) onPositionUpdate;
  final void Function(String type) onSelect;
  final void Function(String type, double newSize) onResize;
  final void Function(String type, String newValue) onTextChange;

  const VideoOverlayItem({
    super.key,
    required this.label,
    required this.x,
    required this.y,
    required this.type,
    required this.constraints,
    required this.color,
    required this.fontSize,
    this.textHeight,
    this.fontWeight = FontWeight.bold,
    this.fontStyle = FontStyle.normal,
    this.textAlign = TextAlign.center,
    this.backgroundColor,
    this.backgroundOpacity = 0.5,
    this.backgroundRadius = 8.0,
    this.isSelected = false,
    required this.onPositionUpdate,
    required this.onSelect,
    required this.onResize,
    required this.onTextChange,
  });

  @override
  State<VideoOverlayItem> createState() => _VideoOverlayItemState();
}

class _VideoOverlayItemState extends State<VideoOverlayItem> {
  late VideoOverlayItemStore _store;

  @override
  void initState() {
    super.initState();
    _store = VideoOverlayItemStore(
      type: widget.type,
      initialLabel: widget.label,
      initialX: widget.x,
      initialY: widget.y,
      constraints: widget.constraints,
      color: widget.color,
      initialFontSize: widget.fontSize,
      onPositionUpdate: widget.onPositionUpdate,
      onSelect: widget.onSelect,
      onResize: widget.onResize,
      onTextChange: widget.onTextChange,
    );
    _store.setSelected(widget.isSelected);
  }

  @override
  void didUpdateWidget(VideoOverlayItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _store.updateLabel(widget.label);
    _store.updatePosition(widget.x, widget.y);
    _store.updateFontSize(widget.fontSize);
    _store.setSelected(widget.isSelected);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF6366F1);
    const hoverColor = Color(0xFF818CF8);

    return Positioned.fill(
      child: Observer(
        builder: (context) => Align(
          alignment: Alignment(_store.x * 2 - 1, _store.y * 2 - 1),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _store.handleSelect,
            onDoubleTap: _store.startEditing,
            onPanStart: (_) {
              _store.setInteracting(true);
              if (!_store.isSelected) _store.handleSelect();
            },
            onPanUpdate: _store.handleDrag,
            onPanEnd: (_) => _store.setInteracting(false),
            onPanCancel: () => _store.setInteracting(false),
            child: MouseRegion(
              onEnter: (_) => _store.setHovered(true),
              onExit: (_) => _store.setHovered(false),
              cursor: _store.isEditing
                  ? SystemMouseCursors.text
                  : SystemMouseCursors.move,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Main Content Box ──
                  AnimatedContainer(
                    key: _store.contentKey,
                    duration: _store.isInteracting
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    constraints: BoxConstraints(
                      maxWidth: _store.constraints.maxWidth,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _store.isSelected
                            ? accentColor
                            : (_store.isHovered
                                  ? hoverColor.withValues(alpha: 0.5)
                                  : Colors.transparent),
                        width: _store.isSelected ? 2 : 1,
                      ),
                      // Khi đang edit, dùng container background như fallback
                      // vì CustomPainter không thể render bên trong TextField
                      color: _store.isEditing && widget.backgroundColor != null
                          ? widget.backgroundColor!.withValues(
                              alpha: widget.backgroundOpacity,
                            )
                          : (_store.isHovered || _store.isSelected
                                ? Colors.black.withValues(alpha: 0.4)
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(
                        widget.backgroundRadius,
                      ),
                      boxShadow: _store.isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: _store.isEditing
                        ? IntrinsicWidth(
                            child: TextField(
                              controller: _store.controller,
                              focusNode: _store.focusNode,
                              autofocus: true,
                              style: TextStyle(
                                color: widget.color,
                                fontSize: _store.fontSize,
                                fontWeight: widget.fontWeight,
                                fontStyle: widget.fontStyle,
                                height: widget.textHeight,
                              ),
                              maxLines: null,
                              textAlign: widget.textAlign,
                              decoration: InputDecoration(
                                isDense: true,
                                // Đồng bộ padding ngang với _LineBackgroundPainter
                                // để editing mode và display mode có cùng kích thước.
                                contentPadding: widget.backgroundColor != null
                                    ? const EdgeInsets.symmetric(horizontal: 16)
                                    : EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) {
                                _store.setEditing(false);
                                _store.onTextChange(
                                  _store.type,
                                  _store.controller.text,
                                );
                              },
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final textStyle = TextStyle(
                                color: widget.color,
                                fontSize: _store.fontSize,
                                fontWeight: widget.fontWeight,
                                fontStyle: widget.fontStyle,
                                height: widget.textHeight,
                              );
                              // Không dùng SizedBox để container giữ compact.
                              // Painter dùng size.width (canvas thực tế) thay vì
                              // maxWidth, nên hệ tọa độ tự đồng nhất.
                              const double bgHPad = 16.0;
                              return CustomPaint(
                                painter: widget.backgroundColor != null
                                    ? _LineBackgroundPainter(
                                        text: _store.label,
                                        textStyle: textStyle,
                                        textAlign: widget.textAlign,
                                        maxWidth: constraints.maxWidth,
                                        backgroundColor: widget.backgroundColor!
                                            .withValues(
                                              alpha: widget.backgroundOpacity,
                                            ),
                                        borderRadius: widget.backgroundRadius,
                                        horizontalPadding: bgHPad,
                                      )
                                    : null,
                                // Không wrap Text trong Padding — làm CustomPaint
                                // rộng hơn khiến TextPainter layout sai không gian
                                // tọa độ → nền bị lệch. Painter tự extend background
                                // qua horizontalPadding mà không cần dịch chuyển text.
                                child: Text(
                                  _store.label,
                                  style: textStyle,
                                  softWrap: true,
                                  textAlign: widget.textAlign,
                                ),
                              );
                            },
                          ),
                  ),

                  // ── 8-Point Resize Handles ──
                  if (_store.isSelected && !_store.isEditing) ...[
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    _buildHandle(
                      top: -16,
                      left: -16,
                      cursor: SystemMouseCursors.resizeUpLeft,
                      onDragStart: () => _store.setInteracting(true),
                      onDragEnd: () => _store.setInteracting(false),
                      onDrag: (d) => _store.handleResize(
                        details: d,
                        multiplierX: -1,
                        multiplierY: -1,
                      ),
                    ),
                    _buildHandle(
                      top: -16,
                      right: -16,
                      cursor: SystemMouseCursors.resizeUpRight,
                      onDragStart: () => _store.setInteracting(true),
                      onDragEnd: () => _store.setInteracting(false),
                      onDrag: (d) => _store.handleResize(
                        details: d,
                        multiplierX: 1,
                        multiplierY: -1,
                      ),
                    ),
                    _buildHandle(
                      bottom: -16,
                      left: -16,
                      cursor: SystemMouseCursors.resizeDownLeft,
                      onDragStart: () => _store.setInteracting(true),
                      onDragEnd: () => _store.setInteracting(false),
                      onDrag: (d) => _store.handleResize(
                        details: d,
                        multiplierX: -1,
                        multiplierY: 1,
                      ),
                    ),
                    _buildHandle(
                      bottom: -16,
                      right: -16,
                      cursor: SystemMouseCursors.resizeDownRight,
                      onDragStart: () => _store.setInteracting(true),
                      onDragEnd: () => _store.setInteracting(false),
                      onDrag: (d) => _store.handleResize(
                        details: d,
                        multiplierX: 1,
                        multiplierY: 1,
                      ),
                    ),
                    _buildHandle(
                      top: -16,
                      left: 0,
                      right: 0,
                      cursor: SystemMouseCursors.resizeUp,
                      onDragStart: () => _store.setInteracting(true),
                      onDragEnd: () => _store.setInteracting(false),
                      onDrag: (d) => _store.handleResize(
                        details: d,
                        multiplierX: 0,
                        multiplierY: -1,
                      ),
                    ),
                    _buildHandle(
                      bottom: -16,
                      left: 0,
                      right: 0,
                      cursor: SystemMouseCursors.resizeDown,
                      onDragStart: () => _store.setInteracting(true),
                      onDragEnd: () => _store.setInteracting(false),
                      onDrag: (d) => _store.handleResize(
                        details: d,
                        multiplierX: 0,
                        multiplierY: 1,
                      ),
                    ),
                    _buildHandle(
                      left: -16,
                      top: 0,
                      bottom: 0,
                      cursor: SystemMouseCursors.resizeLeft,
                      onDragStart: () => _store.setInteracting(true),
                      onDragEnd: () => _store.setInteracting(false),
                      onDrag: (d) => _store.handleResize(
                        details: d,
                        multiplierX: -1,
                        multiplierY: 0,
                      ),
                    ),
                    _buildHandle(
                      right: -16,
                      top: 0,
                      bottom: 0,
                      cursor: SystemMouseCursors.resizeRight,
                      onDragStart: () => _store.setInteracting(true),
                      onDragEnd: () => _store.setInteracting(false),
                      onDrag: (d) => _store.handleResize(
                        details: d,
                        multiplierX: 1,
                        multiplierY: 0,
                      ),
                    ),
                  ],

                  // ── Selection Label ──
                  if (_store.isSelected && !_store.isEditing)
                    Positioned(
                      top: -24,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TEXT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required MouseCursor cursor,
    required void Function(DragUpdateDetails) onDrag,
    required VoidCallback onDragStart,
    required VoidCallback onDragEnd,
  }) {
    const accentColor = Color(0xFF6366F1);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => onDragStart(),
        onPanUpdate: onDrag,
        onPanEnd: (_) => onDragEnd(),
        onPanCancel: () => onDragEnd(),
        child: MouseRegion(
          cursor: cursor,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: accentColor, width: 3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vẽ rounded-rect background phía sau từng dòng text riêng biệt.
/// Sử dụng [TextPainter.computeLineMetrics] để lấy vị trí chính xác từng dòng.
class _LineBackgroundPainter extends CustomPainter {
  const _LineBackgroundPainter({
    required this.text,
    required this.textStyle,
    required this.textAlign,
    required this.maxWidth,
    required this.backgroundColor,
    required this.borderRadius,
    this.horizontalPadding = 16.0,
  });

  final String text;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final double maxWidth;
  final Color backgroundColor;
  final double borderRadius;

  /// Padding ngang thêm vào mỗi bên để nền không sát sát chữ.
  final double horizontalPadding;

  @override
  void paint(Canvas canvas, Size size) {
    // Dùng size.width (kích thước canvas thực tế của CustomPaint widget) thay
    // vì maxWidth. Điều này đảm bảo TextPainter layout trong cùng không gian
    // tọa độ với canvas → line.left tự align đúng mà không cần tính thủ công.
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    final paint = Paint()..color = backgroundColor;
    final lines = textPainter.computeLineMetrics();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.width == 0) continue; // bỏ qua dòng trống

      final bool isFirst = i == 0;
      final bool isLast = i == lines.length - 1;

      // Midpoint approach: chia vertical space tại điểm GIỮA hai baseline kề nhau.
      // Đảm bảo rect[i].bottom == rect[i+1].top về mặt toán học → NO GAP.
      final double top = isFirst
          ? line.baseline - line.ascent
          : (lines[i - 1].baseline + line.baseline) / 2;

      final double bottom = isLast
          ? line.baseline + line.descent
          : (line.baseline + lines[i + 1].baseline) / 2;

      final rect = Rect.fromLTRB(
        line.left - horizontalPadding,
        top,
        line.left + line.width + horizontalPadding,
        bottom,
      );

      // Chỉ bo góc ở mép NGOÀI của toàn bộ text block:
      // - Dòng đầu: bo top-left + top-right
      // - Dòng cuối: bo bottom-left + bottom-right
      // - Điểm nối giữa các dòng: góc vuông → không có vết lõm
      final r = Radius.circular(borderRadius);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: isFirst ? r : Radius.zero,
          topRight: isFirst ? r : Radius.zero,
          bottomLeft: isLast ? r : Radius.zero,
          bottomRight: isLast ? r : Radius.zero,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LineBackgroundPainter old) =>
      text != old.text ||
      textStyle != old.textStyle ||
      backgroundColor != old.backgroundColor ||
      borderRadius != old.borderRadius ||
      maxWidth != old.maxWidth;
}
