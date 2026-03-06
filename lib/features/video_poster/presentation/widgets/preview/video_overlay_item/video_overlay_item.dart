import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final String? fontFamily;
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
    this.fontFamily,
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
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
                        color:
                            _store.isEditing && widget.backgroundColor != null
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
                                style: widget.fontFamily != null
                                    ? GoogleFonts.getFont(
                                        widget.fontFamily!,
                                        color: widget.color,
                                        fontSize: _store.fontSize,
                                        fontWeight: widget.fontWeight,
                                        fontStyle: widget.fontStyle,
                                        height: widget.textHeight,
                                      )
                                    : TextStyle(
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
                                  // Đồng bộ padding ngang với _TextWithLineBackgrounds
                                  // để editing mode và display mode có cùng kích thước.
                                  contentPadding: widget.backgroundColor != null
                                      ? const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        )
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
                          : widget.backgroundColor != null
                          ? _TextWithLineBackgrounds(
                              text: _store.label,
                              textStyle: widget.fontFamily != null
                                  ? GoogleFonts.getFont(
                                      widget.fontFamily!,
                                      color: widget.color,
                                      fontSize: _store.fontSize,
                                      fontWeight: widget.fontWeight,
                                      fontStyle: widget.fontStyle,
                                      height: widget.textHeight,
                                    )
                                  : TextStyle(
                                      color: widget.color,
                                      fontSize: _store.fontSize,
                                      fontWeight: widget.fontWeight,
                                      fontStyle: widget.fontStyle,
                                      height: widget.textHeight,
                                    ),
                              textAlign: widget.textAlign,
                              backgroundColor: widget.backgroundColor!,
                              backgroundOpacity: widget.backgroundOpacity,
                              backgroundRadius: widget.backgroundRadius,
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                _store.label,
                                style: widget.fontFamily != null
                                    ? GoogleFonts.getFont(
                                        widget.fontFamily!,
                                        color: widget.color,
                                        fontSize: _store.fontSize,
                                        fontWeight: widget.fontWeight,
                                        fontStyle: widget.fontStyle,
                                        height: widget.textHeight,
                                      )
                                    : TextStyle(
                                        color: widget.color,
                                        fontSize: _store.fontSize,
                                        fontWeight: widget.fontWeight,
                                        fontStyle: widget.fontStyle,
                                        height: widget.textHeight,
                                      ),
                                softWrap: true,
                                textAlign: widget.textAlign,
                              ),
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

/// Hiển thị text với background BoxDecoration riêng cho từng dòng.
/// Dùng TextPainter.computeLineMetrics() để xác định text thuộc dòng nào,
/// sau đó render mỗi dòng bằng Container(decoration: BoxDecoration) riêng biệt.
class _TextWithLineBackgrounds extends StatelessWidget {
  const _TextWithLineBackgrounds({
    required this.text,
    required this.textStyle,
    required this.textAlign,
    required this.backgroundColor,
    required this.backgroundOpacity,
    required this.backgroundRadius,
  });

  final String text;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final Color backgroundColor;
  final double backgroundOpacity;
  final double backgroundRadius;

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
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(backgroundRadius),
                ),
                child: Text(
                  lineTexts[i],
                  style: textStyle,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: textAlign,
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
      text: TextSpan(text: text, style: textStyle),
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
