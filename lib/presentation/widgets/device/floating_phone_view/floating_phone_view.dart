import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import '../../../../core/di/injection.dart';
import '../../../global_stores/mirroring_store.dart';
import '../phone_view/phone_view.dart';
import 'widgets/floating_tool_box.dart';
import 'widgets/social_share_preview.dart';
import '../../../../domain/entities/poster_data.dart';
import '../../../stores/poster_creation_store.dart';

import 'widgets/floating_window_header.dart';
import 'widgets/floating_resize_handle.dart';
import 'widgets/floating_loading_overlay.dart';

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

  // Poster Workflow State
  bool _isGeneratingPoster = false;
  PosterData? _selectedPosterData;

  final GlobalKey<FloatingToolBoxState> _toolBoxKey = GlobalKey();

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
      if (mounted) {
        setState(() {
          _height = (_width / ratio) + 40 + 12;
          _position = _getClampedPosition(_position);
        });
      }
    });
  }

  @override
  void dispose() {
    _aspectRatioDisposer?.call();
    super.dispose();
  }

  Offset _getClampedPosition(Offset target) {
    if (widget.parentSize.isEmpty) return target;

    // Account for Tool Box width when clamping
    const toolBoxMaxWidth =
        100 + 12 + 12; // expanded width + left margin + spacing
    final totalWidth = _width + toolBoxMaxWidth;

    final maxX = widget.parentSize.width - totalWidth;
    final maxY = widget.parentSize.height - _height;

    return Offset(
      target.dx.clamp(0.0, maxX > 0 ? maxX : 0.0),
      target.dy.clamp(0.0, maxY > 0 ? maxY : 0.0),
    );
  }

  /// Calculate available space for Tool Box
  double _getToolBoxAvailableSpace() {
    if (widget.parentSize.isEmpty) return 0;

    final floatingWindowRight = _position.dx + _width + 12; // + margin
    return widget.parentSize.width - floatingWindowRight;
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
          return Row(
            children: [
              Container(
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
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              // 1. Header Component
                              FloatingWindowHeader(
                                title: widget.serial,
                                onClose: widget.onClose,
                                onDragUpdate: (details) {
                                  setState(() {
                                    _position = _getClampedPosition(
                                      _position + details.delta,
                                    );
                                  });
                                },
                              ),

                              // View Content
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                  ),
                                  child: SizedBox(
                                    width: _width,
                                    height: _height,
                                    child: PhoneView(
                                      serial: widget.serial,
                                      fit: BoxFit.fill,
                                      isFloating: true,
                                      onPosterDropped: (data) async {
                                        final file = await _toolBoxKey
                                            .currentState
                                            ?.capturePoster();
                                        return file;
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              // 2. Resize Handle Component
                              FloatingResizeHandle(
                                onResizeUpdate: (details) {
                                  setState(() {
                                    // Calculate combined delta for proportional scaling
                                    final delta =
                                        details.delta.dx + details.delta.dy;

                                    // Calculate constraints
                                    double maxAllowedWidth = 1200.0;
                                    if (!widget.parentSize.isEmpty) {
                                      final maxWidthByX =
                                          widget.parentSize.width -
                                          _position.dx;
                                      final maxHeightAvailable =
                                          widget.parentSize.height -
                                          _position.dy -
                                          52;
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
                                    _height = (_width / aspectRatio) + 40 + 12;
                                    _position = _getClampedPosition(_position);
                                  });
                                },
                              ),
                            ],
                          ),

                          // // Job Selector Overlay
                          // if (_showJobSelector)
                          //   Positioned.fill(
                          //     child: Container(
                          //       color: Colors.black54,
                          //       child: FloatingJobSelector(
                          //         onCancel: () =>
                          //             setState(() => _showJobSelector = false),
                          //         onJobSelected: (job) async {
                          //           setState(() {
                          //             _showJobSelector = false;
                          //             _isGeneratingPoster = true;
                          //           });

                          //           final store = getIt<PosterCreationStore>();
                          //           await store.selectJob(job);

                          //           if (mounted) {
                          //             setState(() {
                          //               _isGeneratingPoster = false;
                          //               if (store.currentPosterData != null) {
                          //                 _selectedPosterData =
                          //                     store.currentPosterData;
                          //               }
                          //             });
                          //           }
                          //         },
                          //       ),
                          //     ),
                          //   ),

                          // 3. Loading Overlay Component
                          // FloatingLoadingOverlay(
                          //   isVisible: _isGeneratingPoster,
                          // ),

                          // Preview Overlay
                          // if (_selectedPosterData != null)
                          //   Positioned.fill(
                          //     child: Container(
                          //       color: Colors.black54,
                          //       child: SocialSharePreview(
                          //         data: _selectedPosterData!,
                          //         onClose: () => setState(
                          //           () => _selectedPosterData = null,
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              FloatingToolBox(
                key: _toolBoxKey,
                serial: widget.serial,
                height: _height,
                availableSpace: _getToolBoxAvailableSpace(),
                posterData: _selectedPosterData,
                isGenerating: _isGeneratingPoster,
                onJobSelected: (job) async {
                  setState(() {
                    _isGeneratingPoster = true;
                  });

                  final store = getIt<PosterCreationStore>();
                  await store.selectJob(job);

                  if (mounted) {
                    setState(() {
                      _isGeneratingPoster = false;
                      if (store.currentPosterData != null) {
                        _selectedPosterData = store.currentPosterData;
                      }
                    });
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
