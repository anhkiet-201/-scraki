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
  }

  @override
  Widget build(BuildContext context) {
    // Standardized accent color for editor UI
    const accentColor = Color(0xFF6366F1);

    return Positioned.fill(
      child: Align(
        alignment: Alignment(widget.x * 2 - 1, widget.y * 2 - 1),
        child: GestureDetector(
          onTap: () => widget.onSelect(widget.type),
          onDoubleTap: _startEditing,
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
            cursor: _isEditing
                ? SystemMouseCursors.text
                : SystemMouseCursors.move,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main Content Box
                Container(
                  constraints: BoxConstraints(
                    maxWidth: widget.constraints.maxWidth * 0.8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.isSelected ? accentColor : Colors.white24,
                      width: widget.isSelected ? 2 : 1,
                    ),
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: _isEditing
                      ? IntrinsicWidth(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
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
                    right: -10,
                    bottom: -10,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        // Horizontal drag increases size
                        final delta = details.delta.dx + details.delta.dy;
                        widget.onResize(
                          widget.type,
                          widget.fontSize + delta * 0.5,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.open_in_full_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Selection Label (Type)
                if (widget.isSelected && !_isEditing)
                  Positioned(
                    top: -22,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.type.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
