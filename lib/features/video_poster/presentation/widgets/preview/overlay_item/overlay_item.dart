import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/overlay_item/video_overlay_item_store.dart';
import 'package:scraki/overlay/overlay.dart' hide Overlay;

abstract class OverlayItem extends Widget {
  const OverlayItem({super.key});
}

abstract class VideoOverlayItem<T extends OverlayProperties> extends StatefulWidget {
  final T _properties;
  final bool isPreviewMode;

  const VideoOverlayItem({
    super.key,
    required T properties,
    required this.isPreviewMode,
    required this.buildContent,
  }) : _properties = properties;

  final OverlayItem Function(BuildContext context, T properties) buildContent;

  @override
  State<VideoOverlayItem> createState() => _VideoOverlayItemState();
}

class _VideoOverlayItemState<T extends OverlayProperties>
    extends State<VideoOverlayItem<T>>
    with TickerProviderStateMixin {
  late final VideoOverlayItemStore<T> _store;

  @override
  void initState() {
    super.initState();
    _store = VideoOverlayItemStore(properties: widget._properties);
    _store.setSelected(true);
  }

  @override
  void didUpdateWidget(VideoOverlayItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _store.updatePosition(widget._properties.x, widget._properties.y);
    _store.setSelected(widget._properties.isSelected);
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

    return Observer(
      builder: (context) {
        final left =
            _store.properties.x * _store.properties.constraints.maxWidth;
        final top =
            _store.properties.y * _store.properties.constraints.maxHeight;
        final handleSize = (_store.properties.fontSize * 0.5).clamp(24.0, 32.0);
        final handleOffset = -(handleSize / 2);
        const interactionBoxSize = 2000.0;

        return Positioned(
          left: left - (interactionBoxSize / 2),
          top: top - (interactionBoxSize / 2),
          width: interactionBoxSize,
          height: interactionBoxSize,
          child: Opacity(
            opacity: _store.properties.opacity,
            child: SizedBox.expand(
              child: Center(
                child: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.noScaling),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _store.handleSelect,
                    onDoubleTap: _store.startEditing,
                    onPanStart: (_) {
                      _store.setInteracting(true);
                      if (!_store.properties.isSelected) _store.handleSelect();
                    },
                    onPanUpdate: _store.handleDrag,
                    onPanEnd: (_) => _store.setInteracting(false),
                    onPanCancel: () => _store.setInteracting(false),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      color: Colors.transparent,
                      child: MouseRegion(
                        onEnter: (_) => _store.setHovered(true),
                        onExit: (_) => _store.setHovered(false),
                        cursor: _store.properties.isEditing
                            ? SystemMouseCursors.text
                            : SystemMouseCursors.move,
                        child: Transform.rotate(
                          angle: _store.properties.rotation * (math.pi / 180),
                          child: RepaintBoundary(
                            key: _store.properties.captureKey,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _buildMainContent(accentColor, hoverColor),
                                if (_store.properties.isSelected &&
                                    !_store.properties.isEditing) ...[
                                  _buildSelectionBorder(accentColor),
                                  ..._buildResizeHandles(
                                    handleOffset,
                                    handleSize,
                                  ),
                                  _buildSelectionLabel(accentColor),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(Color accentColor, Color hoverColor) {
    return AnimatedContainer(
      key: _store.contentKey,
      duration: _store.properties.isInteracting
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(
        maxWidth: _store.properties.constraints.maxWidth,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: _store.properties.isSelected
              ? accentColor
              : (_store.properties.isHovered
                    ? hoverColor.withValues(alpha: 0.5)
                    : Colors.transparent),
          width: _store.properties.isSelected ? 2 : 1,
        ),
        color: _store.editingBackgroundColor,
        boxShadow: _store.properties.isSelected
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Observer(
        builder: (_) {
          final properties = _store.properties;
          return widget.buildContent(context, properties);
        },
      ),
    );
  }

  Widget _buildSelectionBorder(Color accentColor) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResizeHandles(double handleOffset, double handleSize) {
    return [
      _buildHandle(
        top: handleOffset,
        left: handleOffset,
        size: handleSize,
        cursor: SystemMouseCursors.resizeUpLeft,
        onDrag: (d) => _store.handleResize(
          details: d,
          multiplierX: -1,
          multiplierY: -1,
          rotation: _store.properties.rotation,
        ),
      ),
      _buildHandle(
        top: handleOffset,
        right: handleOffset,
        size: handleSize,
        cursor: SystemMouseCursors.resizeUpRight,
        onDrag: (d) => _store.handleResize(
          details: d,
          multiplierX: 1,
          multiplierY: -1,
          rotation: _store.properties.rotation,
        ),
      ),
      _buildHandle(
        bottom: handleOffset,
        left: handleOffset,
        size: handleSize,
        cursor: SystemMouseCursors.resizeDownLeft,
        onDrag: (d) => _store.handleResize(
          details: d,
          multiplierX: -1,
          multiplierY: 1,
          rotation: _store.properties.rotation,
        ),
      ),
      _buildHandle(
        bottom: handleOffset,
        right: handleOffset,
        size: handleSize,
        cursor: SystemMouseCursors.resizeDownRight,
        onDrag: (d) => _store.handleResize(
          details: d,
          multiplierX: 1,
          multiplierY: 1,
          rotation: _store.properties.rotation,
        ),
      ),
      _buildHandle(
        top: handleOffset,
        left: 0,
        right: 0,
        size: handleSize,
        cursor: SystemMouseCursors.resizeUp,
        onDrag: (d) => _store.handleResize(
          details: d,
          multiplierX: 0,
          multiplierY: -1,
          rotation: _store.properties.rotation,
        ),
      ),
      _buildHandle(
        bottom: handleOffset,
        left: 0,
        right: 0,
        size: handleSize,
        cursor: SystemMouseCursors.resizeDown,
        onDrag: (d) => _store.handleResize(
          details: d,
          multiplierX: 0,
          multiplierY: 1,
          rotation: _store.properties.rotation,
        ),
      ),
      _buildHandle(
        left: handleOffset,
        top: 0,
        bottom: 0,
        size: handleSize,
        cursor: SystemMouseCursors.resizeLeft,
        onDrag: (d) => _store.handleResize(
          details: d,
          multiplierX: -1,
          multiplierY: 0,
          rotation: _store.properties.rotation,
        ),
      ),
      _buildHandle(
        right: handleOffset,
        top: 0,
        bottom: 0,
        size: handleSize,
        cursor: SystemMouseCursors.resizeRight,
        onDrag: (d) => _store.handleResize(
          details: d,
          multiplierX: 1,
          multiplierY: 0,
          rotation: _store.properties.rotation,
        ),
      ),
    ];
  }

  Widget _buildSelectionLabel(Color accentColor) {
    return Positioned(
      top: -24,
      left: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _store.properties.overlayType,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
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
    required double size,
    required MouseCursor cursor,
    required void Function(DragUpdateDetails) onDrag,
  }) {
    const accentColor = Color(0xFF6366F1);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => _store.setInteracting(true),
        onPanUpdate: onDrag,
        onPanEnd: (_) => _store.setInteracting(false),
        onPanCancel: () => _store.setInteracting(false),
        child: MouseRegion(
          cursor: cursor,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: Container(
              width: (size * 0.4).clamp(8.0, 12.0),
              height: (size * 0.4).clamp(8.0, 12.0),
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
