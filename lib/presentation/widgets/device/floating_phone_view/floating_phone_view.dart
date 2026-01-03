import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import '../../../../core/di/injection.dart';
import '../../../global_stores/mirroring_store.dart';
import '../phone_view/phone_view.dart';

class FloatingPhoneView extends StatefulWidget {
  final String serial;
  final VoidCallback onClose;
  final Size parentSize;

  const FloatingPhoneView({
    super.key,
    required this.serial,
    required this.onClose,
    required this.parentSize,
  });

  @override
  State<FloatingPhoneView> createState() => _FloatingPhoneViewState();
}

class _FloatingPhoneViewState extends State<FloatingPhoneView> {
  late final MirroringStore _mirroringStore;
  Offset _position = const Offset(100, 100);
  double _width = 320;
  late double _height;

  ReactionDisposer? _aspectRatioDisposer;

  @override
  void initState() {
    super.initState();
    _mirroringStore = getIt<MirroringStore>();

    // Initial size based on default
    _height = (_width / _mirroringStore.deviceAspectRatio) + 40 + 12;

    // React to aspect ratio changes (e.g. when session starts)
    _aspectRatioDisposer = reaction((_) => _mirroringStore.deviceAspectRatio, (
      ratio,
    ) {
      setState(() {
        _height = (_width / ratio) + 40 + 12;
        _position = _getClampedPosition(_position);
      });
    });
  }

  @override
  void dispose() {
    _aspectRatioDisposer?.call();
    super.dispose();
  }

  Offset _getClampedPosition(Offset target) {
    if (widget.parentSize.isEmpty) return target;

    final maxX = widget.parentSize.width - _width;
    final maxY = widget.parentSize.height - _height;

    return Offset(
      target.dx.clamp(0.0, maxX > 0 ? maxX : 0.0),
      target.dy.clamp(0.0, maxY > 0 ? maxY : 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Observer(
        builder: (_) {
          final aspectRatio = _mirroringStore.deviceAspectRatio;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: _width,
                  height: _height,
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Header / Drag Handle
                      GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _position = _getClampedPosition(
                              _position + details.delta,
                            );
                          });
                        },
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.drag_indicator_rounded,
                                size: 18,
                                color: colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.serial,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                  style: IconButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    foregroundColor: colorScheme.error
                                        .withValues(alpha: 0.8),
                                  ),
                                  onPressed: widget.onClose,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // View Content
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: const BoxDecoration(color: Colors.black),
                          child: SizedBox(
                            width: _width,
                            height: _height,
                            child: PhoneView(
                              serial: widget.serial,
                              fit: BoxFit.fill,
                              isFloating: true,
                            ),
                          ),
                        ),
                      ),
                      // Resize Handle - Proportional
                      GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            // Calculate combined delta for proportional scaling
                            final delta = details.delta.dx + details.delta.dy;

                            // Calculate constraints based on current position and parent size
                            double maxAllowedWidth = 1200.0; // Absolute max
                            if (!widget.parentSize.isEmpty) {
                              final maxWidthByX =
                                  widget.parentSize.width - _position.dx;
                              // height = (width / aspect) + 52
                              // width / aspect <= parentHeight - position.dy - 52
                              final maxHeightAvailable =
                                  widget.parentSize.height - _position.dy - 52;
                              final maxWidthByY =
                                  maxHeightAvailable * aspectRatio;

                              maxAllowedWidth = [
                                maxWidthByX,
                                maxWidthByY,
                                1200.0,
                              ].reduce((a, b) => a < b ? a : b);
                            }

                            final newWidth = (_width + delta).clamp(
                              240.0,
                              maxAllowedWidth,
                            );

                            _width = newWidth;
                            // Recalculate height based on aspect ratio + header + handle
                            _height = (_width / aspectRatio) + 40 + 12;

                            // Re-clamp position if resizing made it go out of bounds
                            _position = _getClampedPosition(_position);
                          });
                        },
                        child: Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(2),
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
        },
      ),
    );
  }
}
