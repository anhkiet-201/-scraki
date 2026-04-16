import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../panels/common/panel_components.dart';
import 'video_overlay_item_store.dart';
import '../../../../domain/entities/custom_text_overlay.dart';

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
  final TextBackgroundStyle backgroundStyle;
  final double backgroundOpacity;
  final double backgroundRadius;
  final String? fontFamily;
  final double rotation;
  final Color? strokeColor;
  final double strokeWidth;
  final double letterSpacing;
  final bool isSelected;
  final void Function(String type, double x, double y) onPositionUpdate;
  final void Function(String type) onSelect;
  final void Function(String type, double nSize) onResize;
  final void Function(String type, String newValue) onTextChange;

  final Color? backgroundBorderColor;
  final double backgroundBorderWidth;
  final double opacity;
  final GlobalKey? captureKey;

  // Animation metadata
  final TextAnimationType animationInType;
  final double animationInDuration;
  final TextAnimationType animationOutType;
  final double animationOutDuration;
  final bool isPreviewMode;
  final double currentTime;
  final double startTime;
  final double endTime;
  final int triggerPreviewCounter;
  final int triggerOutPreviewCounter;

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
    this.backgroundStyle = TextBackgroundStyle.rectangle,
    this.backgroundOpacity = 1.0,
    this.backgroundRadius = 0.0,
    this.backgroundBorderColor,
    this.backgroundBorderWidth = 0.0,
    this.fontFamily,
    this.rotation = 0.0,
    this.strokeColor,
    this.strokeWidth = 0.0,
    this.letterSpacing = 0.0,
    this.isSelected = false,
    this.opacity = 1.0,
    this.captureKey,
    required this.onPositionUpdate,
    required this.onSelect,
    required this.onResize,
    required this.onTextChange,
    // Animation defaults
    this.animationInType = TextAnimationType.none,
    this.animationInDuration = 0.1,
    this.animationOutType = TextAnimationType.none,
    this.animationOutDuration = 0.1,
    this.isPreviewMode = false,
    this.currentTime = 0.0,
    this.startTime = 0.0,
    this.endTime = 10.0,
    this.triggerPreviewCounter = 0,
    this.triggerOutPreviewCounter = 0,
  });

  @override
  State<VideoOverlayItem> createState() => _VideoOverlayItemState();
}

class _VideoOverlayItemState extends State<VideoOverlayItem>
    with TickerProviderStateMixin {
  late VideoOverlayItemStore _store;
  late AnimationController _animController;
  bool _isPreviewingOut = false;

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

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !widget.isPreviewMode) {
          setState(() {
            _isPreviewingOut = false;
            _animController.value = 1.0;
          });
        }
      });

    if (widget.isPreviewMode) {
      _syncAnimationToTime();
    } else {
      _animController.value = 1.0;
    }
  }

  void _syncAnimationToTime() {
    final totalDur = widget.endTime - widget.startTime;
    if (totalDur <= 0) {
      _animController.value = 1.0;
      return;
    }

    final relativeTime = widget.currentTime - widget.startTime;
    final inTime = totalDur * widget.animationInDuration;
    final outStartTime = totalDur * (1.0 - widget.animationOutDuration);

    if (relativeTime < inTime) {
      _animController.value = (relativeTime / inTime).clamp(0.0, 1.0);
    } else if (relativeTime > outStartTime) {
      final outDur = totalDur * widget.animationOutDuration;
      _animController.value =
          ((widget.endTime - widget.currentTime) / outDur).clamp(0.0, 1.0);
    } else {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(VideoOverlayItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _store.updateLabel(widget.label);
    _store.updatePosition(widget.x, widget.y);
    _store.updateFontSize(widget.fontSize);
    _store.setSelected(widget.isSelected);

    if (widget.isPreviewMode) {
      _syncAnimationToTime();
    } else {
      // Trigger one-off previews
      if (widget.triggerPreviewCounter > oldWidget.triggerPreviewCounter) {
        setState(() => _isPreviewingOut = false);
        _animController.forward(from: 0.0);
      } else if (widget.triggerOutPreviewCounter > oldWidget.triggerOutPreviewCounter) {
        setState(() => _isPreviewingOut = true);
        _animController.forward(from: 0.0);
      } else if (oldWidget.isPreviewMode && !widget.isPreviewMode) {
        // Reset to full visibility when leaving preview mode
        _animController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _store.dispose();
    _animController.dispose();
    super.dispose();
  }

  Widget _applyAnimation(Widget child, double progress) {
    // Determine active animation type
    final totalDur = widget.endTime - widget.startTime;
    final relativeTime = widget.currentTime - widget.startTime;
    final outStartTime = totalDur * (1.0 - widget.animationOutDuration);

    final isOutPhase = widget.isPreviewMode 
        ? (relativeTime > outStartTime)
        : _isPreviewingOut;

    final type = isOutPhase ? widget.animationOutType : widget.animationInType;
    // For manual preview (non-preview mode), animController always goes 0 -> 1.
    // For sync preview mode, animController already goes 1 -> 0 during out phase.
    final rawProgress = (isOutPhase && !widget.isPreviewMode) 
        ? (1.0 - progress) 
        : progress;

    // Apply easing curve for smoother animation
    final effectiveProgress = Curves.easeInOut.transform(rawProgress);

    if (type == TextAnimationType.none) return child;

    return switch (type) {
      TextAnimationType.fade => Opacity(
          opacity: effectiveProgress,
          child: child,
        ),
      TextAnimationType.zoom => Transform.scale(
          scale: effectiveProgress,
          child: child,
        ),
      TextAnimationType.slideUp => Transform.translate(
          offset: Offset(0, isOutPhase ? -50 * (1 - rawProgress) : 50 * (1 - rawProgress)),
          child: child,
        ),
      TextAnimationType.slideDown => Transform.translate(
          offset: Offset(0, isOutPhase ? 50 * (1 - rawProgress) : -50 * (1 - rawProgress)),
          child: child,
        ),
      TextAnimationType.slideLeft => Transform.translate(
          offset: Offset(isOutPhase ? -50 * (1 - rawProgress) : 50 * (1 - rawProgress), 0),
          child: child,
        ),
      TextAnimationType.slideRight => Transform.translate(
          offset: Offset(isOutPhase ? 50 * (1 - rawProgress) : -50 * (1 - rawProgress), 0),
          child: child,
        ),
      _ => child,
    };
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF6366F1);
    const hoverColor = Color(0xFF818CF8);

    return Observer(
      builder: (context) {
        // Center of the item in pixels
        final left = _store.x * _store.constraints.maxWidth;
        final top = _store.y * _store.constraints.maxHeight;

        // Dynamic handle metrics to prevent overlap on small text
        // and keep them usable on large text.
        final handleSize = (_store.fontSize * 0.5).clamp(24.0, 32.0);
        final handleOffset = -(handleSize / 2);

        // We use a large Positioned box centered at (left, top)
        // instead of FractionalTranslation to avoid hit-test clipping issues in the Stack.
        const interactionBoxSize = 2000.0;

        return Positioned(
          left: left - (interactionBoxSize / 2),
          top: top - (interactionBoxSize / 2),
          width: interactionBoxSize,
          height: interactionBoxSize,
          child: Opacity(
            opacity: widget.opacity,
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
                      if (!_store.isSelected) _store.handleSelect();
                    },
                    onPanUpdate: _store.handleDrag,
                    onPanEnd: (_) => _store.setInteracting(false),
                    onPanCancel: () => _store.setInteracting(false),
                    child: Container(
                      // Ensure a minimum hit target even for tiny text
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      color: Colors.transparent,
                      child: MouseRegion(
                        onEnter: (_) => _store.setHovered(true),
                        onExit: (_) => _store.setHovered(false),
                        cursor: _store.isEditing
                            ? SystemMouseCursors.text
                            : SystemMouseCursors.move,
                        child: Transform.rotate(
                          angle: widget.rotation * (math.pi / 180),
                          child: RepaintBoundary(
                            key: widget.captureKey,
                            child: AnimatedBuilder(
                              animation: _animController,
                              builder: (context, child) {
                                return _applyAnimation(child!, _animController.value);
                              },
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
                                    color:
                                        _store.isEditing &&
                                            widget.backgroundColor != null
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
                                                ? PanelComponents.getSafeFont(
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
                                                    letterSpacing:
                                                        widget.letterSpacing,
                                                  ),
                                            maxLines: null,
                                            textAlign: widget.textAlign,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  widget.backgroundColor != null
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
                                          style: widget.fontFamily != null
                                              ? PanelComponents.getSafeFont(
                                                  widget.fontFamily!,
                                                  color: widget.color,
                                                  fontSize: _store.fontSize,
                                                  fontWeight: widget.fontWeight,
                                                  fontStyle: widget.fontStyle,
                                                  height: widget.textHeight,
                                                  letterSpacing:
                                                      widget.letterSpacing,
                                                )
                                              : TextStyle(
                                                  color: widget.color,
                                                  fontSize: _store.fontSize,
                                                  fontWeight: widget.fontWeight,
                                                  fontStyle: widget.fontStyle,
                                                  height: widget.textHeight,
                                                  letterSpacing:
                                                      widget.letterSpacing,
                                                ),
                                          textAlign: widget.textAlign,
                                          backgroundColor:
                                              widget.backgroundColor!,
                                          backgroundOpacity:
                                              widget.backgroundOpacity,
                                          backgroundRadius:
                                              widget.backgroundRadius,
                                          backgroundStyle:
                                              widget.backgroundStyle,
                                          backgroundBorderColor:
                                              widget.backgroundBorderColor,
                                          backgroundBorderWidth:
                                              widget.backgroundBorderWidth,
                                          strokeColor: widget.strokeColor,
                                          strokeWidth: widget.strokeWidth,
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Stack(
                                            children: [
                                              if (widget.strokeColor != null &&
                                                  widget.strokeWidth > 0)
                                                Text(
                                                  _store.label,
                                                  style:
                                                      (widget.fontFamily != null
                                                              ? PanelComponents.getSafeFont(
                                                                  widget
                                                                      .fontFamily!,
                                                                  fontSize: _store
                                                                      .fontSize,
                                                                  fontWeight: widget
                                                                      .fontWeight,
                                                                  fontStyle: widget
                                                                      .fontStyle,
                                                                  height: widget
                                                                      .textHeight,
                                                                  letterSpacing:
                                                                      widget
                                                                          .letterSpacing,
                                                                )
                                                              : TextStyle(
                                                                  fontSize: _store
                                                                      .fontSize,
                                                                  fontWeight: widget
                                                                      .fontWeight,
                                                                  fontStyle: widget
                                                                      .fontStyle,
                                                                  height: widget
                                                                      .textHeight,
                                                                  letterSpacing:
                                                                      widget
                                                                          .letterSpacing,
                                                                ))
                                                          .copyWith(
                                                            foreground: Paint()
                                                              ..style =
                                                                  PaintingStyle
                                                                      .stroke
                                                              ..strokeJoin =
                                                                  StrokeJoin.round
                                                              ..strokeCap =
                                                                  StrokeCap.round
                                                              ..strokeWidth =
                                                                  widget
                                                                      .strokeWidth
                                                              ..color = widget
                                                                  .strokeColor!,
                                                          ),
                                                  softWrap: true,
                                                  textAlign: widget.textAlign,
                                                ),
                                              Text(
                                                _store.label,
                                                style: widget.fontFamily != null
                                                    ? PanelComponents.getSafeFont(
                                                        widget.fontFamily!,
                                                        color: widget.color,
                                                        fontSize: _store.fontSize,
                                                        fontWeight:
                                                            widget.fontWeight,
                                                        fontStyle:
                                                            widget.fontStyle,
                                                        height: widget.textHeight,
                                                        letterSpacing:
                                                            widget.letterSpacing,
                                                      )
                                                    : TextStyle(
                                                        color: widget.color,
                                                        fontSize: _store.fontSize,
                                                        fontWeight:
                                                            widget.fontWeight,
                                                        fontStyle:
                                                            widget.fontStyle,
                                                        height: widget.textHeight,
                                                        letterSpacing:
                                                            widget.letterSpacing,
                                                      ),
                                                softWrap: true,
                                                textAlign: widget.textAlign,
                                              ),
                                            ],
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
                                    top: handleOffset,
                                    left: handleOffset,
                                    size: handleSize,
                                    cursor: SystemMouseCursors.resizeUpLeft,
                                    onDragStart: () =>
                                        _store.setInteracting(true),
                                    onDragEnd: () => _store.setInteracting(false),
                                    onDrag: (d) => _store.handleResize(
                                      details: d,
                                      multiplierX: -1,
                                      multiplierY: -1,
                                      rotation: widget.rotation,
                                    ),
                                  ),
                                  _buildHandle(
                                    top: handleOffset,
                                    right: handleOffset,
                                    size: handleSize,
                                    cursor: SystemMouseCursors.resizeUpRight,
                                    onDragStart: () =>
                                        _store.setInteracting(true),
                                    onDragEnd: () => _store.setInteracting(false),
                                    onDrag: (d) => _store.handleResize(
                                      details: d,
                                      multiplierX: 1,
                                      multiplierY: -1,
                                      rotation: widget.rotation,
                                    ),
                                  ),
                                  _buildHandle(
                                    bottom: handleOffset,
                                    left: handleOffset,
                                    size: handleSize,
                                    cursor: SystemMouseCursors.resizeDownLeft,
                                    onDragStart: () =>
                                        _store.setInteracting(true),
                                    onDragEnd: () => _store.setInteracting(false),
                                    onDrag: (d) => _store.handleResize(
                                      details: d,
                                      multiplierX: -1,
                                      multiplierY: 1,
                                      rotation: widget.rotation,
                                    ),
                                  ),
                                  _buildHandle(
                                    bottom: handleOffset,
                                    right: handleOffset,
                                    size: handleSize,
                                    cursor: SystemMouseCursors.resizeDownRight,
                                    onDragStart: () =>
                                        _store.setInteracting(true),
                                    onDragEnd: () => _store.setInteracting(false),
                                    onDrag: (d) => _store.handleResize(
                                      details: d,
                                      multiplierX: 1,
                                      multiplierY: 1,
                                      rotation: widget.rotation,
                                    ),
                                  ),
                                  _buildHandle(
                                    top: handleOffset,
                                    left: 0,
                                    right: 0,
                                    size: handleSize,
                                    cursor: SystemMouseCursors.resizeUp,
                                    onDragStart: () =>
                                        _store.setInteracting(true),
                                    onDragEnd: () => _store.setInteracting(false),
                                    onDrag: (d) => _store.handleResize(
                                      details: d,
                                      multiplierX: 0,
                                      multiplierY: -1,
                                      rotation: widget.rotation,
                                    ),
                                  ),
                                  _buildHandle(
                                    bottom: handleOffset,
                                    left: 0,
                                    right: 0,
                                    size: handleSize,
                                    cursor: SystemMouseCursors.resizeDown,
                                    onDragStart: () =>
                                        _store.setInteracting(true),
                                    onDragEnd: () => _store.setInteracting(false),
                                    onDrag: (d) => _store.handleResize(
                                      details: d,
                                      multiplierX: 0,
                                      multiplierY: 1,
                                      rotation: widget.rotation,
                                    ),
                                  ),
                                  _buildHandle(
                                    left: handleOffset,
                                    top: 0,
                                    bottom: 0,
                                    size: handleSize,
                                    cursor: SystemMouseCursors.resizeLeft,
                                    onDragStart: () =>
                                        _store.setInteracting(true),
                                    onDragEnd: () => _store.setInteracting(false),
                                    onDrag: (d) => _store.handleResize(
                                      details: d,
                                      multiplierX: -1,
                                      multiplierY: 0,
                                      rotation: widget.rotation,
                                    ),
                                  ),
                                  _buildHandle(
                                    right: handleOffset,
                                    top: 0,
                                    bottom: 0,
                                    size: handleSize,
                                    cursor: SystemMouseCursors.resizeRight,
                                    onDragStart: () =>
                                        _store.setInteracting(true),
                                    onDragEnd: () => _store.setInteracting(false),
                                    onDrag: (d) => _store.handleResize(
                                      details: d,
                                      multiplierX: 1,
                                      multiplierY: 0,
                                      rotation: widget.rotation,
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
    required double size,
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

class _TextWithLineBackgrounds extends StatelessWidget {
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

  const _TextWithLineBackgrounds({
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
                      ? _BrushBackgroundPainter(color: bgColor)
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

class _BrushBackgroundPainter extends CustomPainter {
  final Color color;

  _BrushBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    
    // Nới rộng vùng vẽ để các nét cọ có không gian "bay bổng"
    const paddingX = 30.0;
    const paddingY = 10.0;
    final rect = Rect.fromLTWH(
      -paddingX, 
      -paddingY, 
      size.width + paddingX * 2, 
      size.height + paddingY * 2
    );

    // 1. Độ cong và độ nghiêng tổng thể
    final globalCurve = (random.nextDouble() - 0.5) * 15.0; // Độ võng của nét cọ
    final globalTilt = (random.nextDouble() - 0.5) * 0.05;  // Độ nghiêng (radians)

    canvas.save();
    // Xoay nhẹ khung hình để tạo độ vát
    canvas.rotate(globalTilt);

    // 2. Vẽ các vệt cọ (Streaks) bằng đường cong
    final numStreaks = 12; // Tăng số lượng vệt để mịn hơn
    for (int i = 0; i < numStreaks; i++) {
        final streakOpacity = 0.2 + (random.nextDouble() * 0.5);
        final streakPaint = Paint()
          ..color = color.withValues(alpha: streakOpacity)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = (rect.height / (numStreaks / 1.5)) * (0.8 + random.nextDouble() * 0.5);

        final path = Path();
        
        // Độ dài ngẫu nhiên mạnh để phá dáng vuông
        final startX = rect.left + (random.nextDouble() * 40.0);
        final endX = rect.right - (random.nextDouble() * 40.0);
        final yBase = rect.top + (rect.height / numStreaks) * i;
        
        path.moveTo(startX, yBase);
        
        // Vẽ đường cong Quadratic Bezier để tạo độ võng tự nhiên
        final controlX = (startX + endX) / 2;
        final controlY = yBase + globalCurve + (random.nextDouble() - 0.5) * 10.0;
        
        path.quadraticBezierTo(controlX, controlY, endX, yBase + (random.nextDouble() - 0.5) * 5.0);

        // Thêm một chút nhiễu cho đường cong (jitter)
        canvas.drawPath(_createJitteredPath(path, random, intensity: 1.5), streakPaint);
    }

    // 3. Hiệu ứng lông cọ khô (Dry bristles) và vệt mực văng
    final bristlePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 50; i++) {
      final y = rect.top + random.nextDouble() * rect.height;
      final isLeft = random.nextBool();
      final length = 10.0 + random.nextDouble() * 25.0;
      final xStart = isLeft ? rect.left : rect.right - length;
      final xOffset = (random.nextDouble() - 0.5) * 10.0;
      
      canvas.drawLine(
        Offset(xStart + xOffset, y),
        Offset(xStart + length + xOffset, y + (random.nextDouble() - 0.5) * 3.0),
        bristlePaint
      );
    }

    // 4. Thêm các vết đốm mực nhỏ (Splats) để trông "thật" hơn
    final splatPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 15; i++) {
      final x = rect.left + random.nextDouble() * rect.width;
      final y = rect.top + random.nextDouble() * rect.height;
      final r = 0.5 + random.nextDouble() * 2.0;
      canvas.drawCircle(Offset(x, y), r, splatPaint);
    }

    canvas.restore();
  }

  Path _createJitteredPath(Path source, math.Random random, {double intensity = 2.0}) {
    final Path jitteredPath = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      final double length = metric.length;
      final int segments = (length / 5.0).clamp(2, 200).toInt();
      
      bool first = true;
      for (int i = 0; i <= segments; i++) {
        final double t = i / segments;
        final Tangent? tangent = metric.getTangentForOffset(length * t);
        if (tangent != null) {
          final Offset normal = Offset(-tangent.vector.dy, tangent.vector.dx);
          final double jitter = (random.nextDouble() - 0.5) * intensity;
          final Offset point = tangent.position + normal * jitter;
          
          if (first) {
            jitteredPath.moveTo(point.dx, point.dy);
            first = false;
          } else {
            jitteredPath.lineTo(point.dx, point.dy);
          }
        }
      }
    }
    return jitteredPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
