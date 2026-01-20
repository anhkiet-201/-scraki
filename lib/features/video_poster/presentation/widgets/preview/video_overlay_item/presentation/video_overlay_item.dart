import 'package:flutter/material.dart';

/// Draggable and interactive text overlay item for video preview
class VideoOverlayItem extends StatefulWidget {
  final String label;
  final double x;
  final double y;
  final String type;
  final BoxConstraints constraints;
  final Color color;
  final double fontSize;
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
  bool _isEditing = false;
  bool _isHovered = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.label);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        setState(() => _isEditing = false);
        widget.onTextChange(widget.type, _controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(VideoOverlayItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label && !_isEditing) {
      _controller.text = widget.label;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    _focusNode.requestFocus();
    // Professional touch: Auto-select all text on double click
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF6366F1);
    const hoverColor = Color(0xFF818CF8);

    return Positioned.fill(
      child: Align(
        alignment: Alignment(widget.x * 2 - 1, widget.y * 2 - 1),
        child: GestureDetector(
          onTap: () => widget.onSelect(widget.type),
          onDoubleTap: _startEditing,
          onPanStart: (_) {
            // Instant selection on pan start for seamlessness
            if (!widget.isSelected) widget.onSelect(widget.type);
          },
          onPanUpdate: (details) {
            if (_isEditing) return;
            final newX =
                (widget.x + details.delta.dx / widget.constraints.maxWidth)
                    .clamp(0.0, 1.0);
            final newY =
                (widget.y + details.delta.dy / widget.constraints.maxHeight)
                    .clamp(0.0, 1.0);
            widget.onPositionUpdate(widget.type, newX, newY);
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            cursor: _isEditing
                ? SystemMouseCursors.text
                : SystemMouseCursors.move,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main Content Box
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  constraints: BoxConstraints(
                    maxWidth: widget.constraints.maxWidth * 0.8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.isSelected
                          ? accentColor
                          : (_isHovered
                                ? hoverColor.withValues(alpha: 0.5)
                                : Colors.white24),
                      width: widget.isSelected ? 2 : 1,
                    ),
                    color: Colors.black.withValues(
                      alpha: _isHovered || widget.isSelected ? 0.6 : 0.4,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ]
                        : (_isHovered
                              ? [
                                  BoxShadow(
                                    color: hoverColor.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null),
                  ),
                  child: _isEditing
                      ? IntrinsicWidth(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: true,
                            style: TextStyle(
                              color: widget.color,
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: null,
                            textAlign:
                                widget.type == 'requirements' ||
                                    widget.type == 'benefits'
                                ? TextAlign.left
                                : TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) {
                              setState(() => _isEditing = false);
                              widget.onTextChange(
                                widget.type,
                                _controller.text,
                              );
                            },
                          ),
                        )
                      : Text(
                          widget.label,
                          style: TextStyle(
                            color: widget.color,
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                          softWrap: true,
                          textAlign:
                              widget.type == 'requirements' ||
                                  widget.type == 'benefits'
                              ? TextAlign.left
                              : TextAlign.center,
                        ),
                ),

                // Resize Handle
                if (widget.isSelected && !_isEditing)
                  Positioned(
                    right: -15, // Larger hit area
                    bottom: -15,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        // Smooth resizing logic using diagonal distance
                        final delta = details.delta.dx + details.delta.dy;
                        widget.onResize(
                          widget.type,
                          widget.fontSize + delta * 0.5,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(
                          8,
                        ), // Padding for hit area
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.open_in_full_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Selection Label (Type)
                if (widget.isSelected && !_isEditing)
                  Positioned(
                    top: -24,
                    left: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: widget.isSelected ? 1.0 : 0.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
