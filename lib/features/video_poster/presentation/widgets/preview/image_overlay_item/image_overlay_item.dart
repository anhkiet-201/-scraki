import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'image_overlay_item_store.dart';
import 'dart:io';

/// Draggable and resizable image overlay item for video preview.
class ImageOverlayItem extends StatefulWidget {
  final String id;
  final String imageUrl;
  final bool isGif;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final BoxConstraints constraints;
  final bool isSelected;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final void Function(String id, double x, double y) onPositionUpdate;
  final void Function(String id) onSelect;
  final void Function(String id, double newWidth, double newHeight) onResize;

  const ImageOverlayItem({
    super.key,
    required this.id,
    required this.imageUrl,
    this.isGif = false,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    required this.constraints,
    this.isSelected = false,
    this.borderColor,
    this.borderWidth = 0.0,
    this.borderRadius = 0.0,
    required this.onPositionUpdate,
    required this.onSelect,
    required this.onResize,
  });

  @override
  State<ImageOverlayItem> createState() => _ImageOverlayItemState();
}

class _ImageOverlayItemState extends State<ImageOverlayItem> {
  late ImageOverlayItemStore _store;

  @override
  void initState() {
    super.initState();
    _store = ImageOverlayItemStore(
      id: widget.id,
      initialX: widget.x,
      initialY: widget.y,
      initialWidth: widget.width,
      initialHeight: widget.height,
      constraints: widget.constraints,
      onPositionUpdate: widget.onPositionUpdate,
      onSelect: widget.onSelect,
      onResize: widget.onResize,
    );
    _store.setSelected(widget.isSelected);
  }

  @override
  void didUpdateWidget(ImageOverlayItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _store.updatePosition(widget.x, widget.y);
    _store.updateSize(widget.width, widget.height);
    _store.setSelected(widget.isSelected);
  }

  Widget _buildImageProvider() {
    if (widget.imageUrl.startsWith('http')) {
      return Image.network(
        widget.imageUrl,
        fit: BoxFit.fill,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.error, color: Colors.red),
      );
    } else if (widget.imageUrl.startsWith('assets/')) {
      return Image.asset(widget.imageUrl, fit: BoxFit.fill);
    } else {
      return Image.file(
        File(widget.imageUrl),
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.error, color: Colors.blue),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF6366F1);
    const hoverColor = Color(0xFF818CF8);
    // Padding nội bộ giúp handle góc luôn nằm trong bounds của SizedBox
    const pad = 16.0;

    return Observer(
      builder: (context) {
        final left = _store.x * _store.constraints.maxWidth;
        final top = _store.y * _store.constraints.maxHeight;
        final w = _store.width;
        final h = _store.height;

        return Positioned(
          left: left,
          top: top,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: MouseRegion(
              onEnter: (_) => _store.setHovered(true),
              onExit: (_) => _store.setHovered(false),
              child: Transform.rotate(
                angle: widget.rotation * (3.141592653589793 / 180),
                child: SizedBox(
                  // SizedBox lớn hơn ảnh 2*pad mỗi chiều
                  // Handle tại góc (0,0) chính xác bằng với góc ảnh
                  width: w + pad * 2,
                  height: h + pad * 2,
                  child: Stack(
                    children: [
                      // ── Ảnh nằm tại (pad, pad) bên trong SizedBox ──
                      Positioned(
                        top: pad,
                        left: pad,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _store.handleSelect,
                          onPanStart: (_) {
                            _store.setInteracting(true);
                            if (!_store.isSelected) _store.handleSelect();
                          },
                          onPanUpdate: (d) =>
                              _store.handleDrag(d, widget.rotation),
                          onPanEnd: (_) => _store.setInteracting(false),
                          onPanCancel: () => _store.setInteracting(false),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.move,
                            child: AnimatedContainer(
                              key: _store.contentKey,
                              duration: _store.isInteracting
                                  ? Duration.zero
                                  : const Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              width: w,
                              height: h,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _store.isSelected
                                        ? accentColor
                                        : (_store.isHovered
                                              ? hoverColor.withValues(alpha: 0.5)
                                              : Colors.transparent),
                                    width: _store.isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(widget.borderRadius),
                                    border: widget.borderWidth > 0 &&
                                            widget.borderColor != null
                                        ? Border.all(
                                            color: widget.borderColor!,
                                            width: widget.borderWidth,
                                          )
                                        : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      (widget.borderRadius - widget.borderWidth)
                                          .clamp(0, double.infinity),
                                    ),
                                    child: _buildImageProvider(),
                                  ),
                                ),
                              ),
                          ),
                        ),
                      ),

                      // ── Resize Handles (chỉ khi selected) ──────────────
                      if (_store.isSelected) ...[
                        // Viền selection
                        Positioned(
                          top: pad,
                          left: pad,
                          child: IgnorePointer(
                            child: Container(
                              width: w,
                              height: h,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Góc TL — tại (0, 0) trong SizedBox = góc ảnh
                        _buildHandle(
                          top: 0,
                          left: 0,
                          cursor: SystemMouseCursors.resizeUpLeft,
                          onDragStart: () => _store.setInteracting(true),
                          onDragEnd: () => _store.setInteracting(false),
                          onDrag: (d) => _store.handleResize(
                            details: d,
                            multiplierX: -1,
                            multiplierY: -1,
                            rotation: widget.rotation,
                          ),
                        ),
                        // Góc TR
                        _buildHandle(
                          top: 0,
                          left: w,
                          cursor: SystemMouseCursors.resizeUpRight,
                          onDragStart: () => _store.setInteracting(true),
                          onDragEnd: () => _store.setInteracting(false),
                          onDrag: (d) => _store.handleResize(
                            details: d,
                            multiplierX: 1,
                            multiplierY: -1,
                            rotation: widget.rotation,
                          ),
                        ),
                        // Góc BL
                        _buildHandle(
                          top: h,
                          left: 0,
                          cursor: SystemMouseCursors.resizeDownLeft,
                          onDragStart: () => _store.setInteracting(true),
                          onDragEnd: () => _store.setInteracting(false),
                          onDrag: (d) => _store.handleResize(
                            details: d,
                            multiplierX: -1,
                            multiplierY: 1,
                            rotation: widget.rotation,
                          ),
                        ),
                        // Góc BR
                        _buildHandle(
                          top: h,
                          left: w,
                          cursor: SystemMouseCursors.resizeDownRight,
                          onDragStart: () => _store.setInteracting(true),
                          onDragEnd: () => _store.setInteracting(false),
                          onDrag: (d) => _store.handleResize(
                            details: d,
                            multiplierX: 1,
                            multiplierY: 1,
                            rotation: widget.rotation,
                          ),
                        ),

                        // Cạnh Top
                        _buildHandle(
                          top: 0,
                          left: w / 2,
                          cursor: SystemMouseCursors.resizeUp,
                          onDragStart: () => _store.setInteracting(true),
                          onDragEnd: () => _store.setInteracting(false),
                          onDrag: (d) => _store.handleResize(
                            details: d,
                            multiplierX: 0,
                            multiplierY: -1,
                            rotation: widget.rotation,
                          ),
                        ),
                        // Cạnh Bottom
                        _buildHandle(
                          top: h,
                          left: w / 2,
                          cursor: SystemMouseCursors.resizeDown,
                          onDragStart: () => _store.setInteracting(true),
                          onDragEnd: () => _store.setInteracting(false),
                          onDrag: (d) => _store.handleResize(
                            details: d,
                            multiplierX: 0,
                            multiplierY: 1,
                            rotation: widget.rotation,
                          ),
                        ),
                        // Cạnh Left
                        _buildHandle(
                          top: h / 2,
                          left: 0,
                          cursor: SystemMouseCursors.resizeLeft,
                          onDragStart: () => _store.setInteracting(true),
                          onDragEnd: () => _store.setInteracting(false),
                          onDrag: (d) => _store.handleResize(
                            details: d,
                            multiplierX: -1,
                            multiplierY: 0,
                            rotation: widget.rotation,
                          ),
                        ),
                        // Cạnh Right
                        _buildHandle(
                          top: h / 2,
                          left: w,
                          cursor: SystemMouseCursors.resizeRight,
                          onDragStart: () => _store.setInteracting(true),
                          onDragEnd: () => _store.setInteracting(false),
                          onDrag: (d) => _store.handleResize(
                            details: d,
                            multiplierX: 1,
                            multiplierY: 0,
                            rotation: widget.rotation,
                          ),
                        ),

                        // Label GIF/IMAGE
                        Positioned(
                          top: pad + 4,
                          left: pad + 4,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.isGif ? 'GIF' : 'IMAGE',
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
