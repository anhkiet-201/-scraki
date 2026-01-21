import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'video_overlay_item_store.dart';

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
                  // Main Content Box
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
                                  : Colors.white24),
                        width: _store.isSelected ? 2 : 1,
                      ),
                      color: Colors.black.withValues(
                        alpha: _store.isHovered || _store.isSelected
                            ? 0.6
                            : 0.4,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _store.isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ]
                          : (_store.isHovered
                                ? [
                                    BoxShadow(
                                      color: hoverColor.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null),
                    ),
                    child: _store.isEditing
                        ? IntrinsicWidth(
                            child: TextField(
                              controller: _store.controller,
                              focusNode: _store.focusNode,
                              autofocus: true,
                              style: TextStyle(
                                color: _store.color,
                                fontSize: _store.fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: null,
                              textAlign:
                                  _store.type == 'requirements' ||
                                      _store.type == 'benefits'
                                  ? TextAlign.left
                                  : TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
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
                        : Text(
                            _store.label,
                            style: TextStyle(
                              color: _store.color,
                              fontSize: _store.fontSize,
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
                                _store.type == 'requirements' ||
                                    _store.type == 'benefits'
                                ? TextAlign.left
                                : TextAlign.center,
                          ),
                  ),

                  // 8-Point Transform Handles (Positioned outside to prevent blocking text interaction)
                  if (_store.isSelected && !_store.isEditing) ...[
                    // Bounding Box Border (Inner)
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

                    // Corners
                    _buildHandle(
                      top: -16,
                      left: -16,
                      cursor: SystemMouseCursors.resizeUpLeft,
                      onDragStart: () => _store.setInteracting(true),
                      onDragEnd: () => _store.setInteracting(false),
                      onDrag: (details) => _store.handleResize(
                        details: details,
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
                      onDrag: (details) => _store.handleResize(
                        details: details,
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
                      onDrag: (details) => _store.handleResize(
                        details: details,
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
                      onDrag: (details) => _store.handleResize(
                        details: details,
                        multiplierX: 1,
                        multiplierY: 1,
                      ),
                    ),

                    // Mid-Points
                    _buildHandle(
                      top: -16,
                      left: 0,
                      right: 0,
                      cursor: SystemMouseCursors.resizeUp,
                      onDragStart: () => _store.setInteracting(true),
                      onDragEnd: () => _store.setInteracting(false),
                      onDrag: (details) => _store.handleResize(
                        details: details,
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
                      onDrag: (details) => _store.handleResize(
                        details: details,
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
                      onDrag: (details) => _store.handleResize(
                        details: details,
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
                      onDrag: (details) => _store.handleResize(
                        details: details,
                        multiplierX: 1,
                        multiplierY: 0,
                      ),
                    ),
                  ],

                  // Selection Label (Type)
                  if (_store.isSelected && !_store.isEditing)
                    Positioned(
                      top: -24,
                      left: 0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _store.isSelected ? 1.0 : 0.0,
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
                            _store.type.toUpperCase(),
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
            width: 32, // Larger touch target
            height: 32,
            alignment: Alignment.center,
            child: Container(
              width: 12, // Larger visual circle
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
