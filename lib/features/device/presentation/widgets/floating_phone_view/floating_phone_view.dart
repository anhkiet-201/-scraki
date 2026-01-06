import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/features/poster/presentation/stores/poster_creation_store.dart';
import '../phone_view/phone_view.dart';
import 'widgets/floating_tool_box/floating_tool_box.dart';
import 'widgets/floating_window_header.dart';
import 'widgets/floating_resize_handle.dart';
import 'store/floating_phone_view_store.dart';

/// Widget hiển thị cửa sổ điện thoại nổi (Floating Window).
///
/// Bao gồm:
/// - Header: Tiêu đề và nút đóng, hỗ trợ kéo thả
/// - Content: Hiển thị màn hình điện thoại (PhoneView)
/// - Resize Handle: Cho phép thay đổi kích thước
/// - ToolBox: Các công cụ hỗ trợ (Power, Poster)
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

class _FloatingPhoneViewState extends State<FloatingPhoneView>
    with SessionManagerStoreMixin {
  late final FloatingPhoneViewStore _store;
  final GlobalKey<FloatingToolBoxState> _toolBoxKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _store = FloatingPhoneViewStore(widget.parentSize);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Observer(
      builder: (_) {
        final aspectRatio = sessionManagerStore.deviceAspectRatio;
        return Positioned(
          left: _store.position.dx,
          top: _store.position.dy,
          child: Row(
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
                      width: _store.width,
                      height: _store.height,
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
                                  runInAction(() {
                                    final newPosition = _store
                                        .getClampedPosition(
                                          _store.position + details.delta,
                                          widget.parentSize,
                                        );
                                    _store.updatePosition(newPosition);
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
                                    width: _store.width,
                                    height: _store.height,
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
                                  runInAction(() {
                                    // Calculate combined delta for proportional scaling
                                    final delta =
                                        details.delta.dx + details.delta.dy;

                                    // Calculate constraints
                                    double maxAllowedWidth = 1200.0;
                                    if (!widget.parentSize.isEmpty) {
                                      final maxWidthByX =
                                          widget.parentSize.width -
                                          _store.position.dx;
                                      final maxHeightAvailable =
                                          widget.parentSize.height -
                                          _store.position.dy -
                                          52;
                                      final maxWidthByY =
                                          maxHeightAvailable * aspectRatio;

                                      maxAllowedWidth = [
                                        maxWidthByX,
                                        maxWidthByY,
                                        1200.0,
                                      ].reduce((a, b) => a < b ? a : b);
                                    }

                                    final newWidth = (_store.width + delta)
                                        .clamp(240.0, maxAllowedWidth);

                                    final newHeight =
                                        (newWidth / aspectRatio) + 40 + 12;
                                    _store.updateDimensions(
                                      newWidth,
                                      newHeight,
                                    );
                                    _store.updatePosition(
                                      _store.getClampedPosition(
                                        _store.position,
                                        widget.parentSize,
                                      ),
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              FloatingToolBox(
                key: _toolBoxKey,
                serial: widget.serial,
                height: _store.height,
                availableSpace: _store.getToolBoxAvailableSpace(
                  widget.parentSize,
                ),
                posterData: _store.selectedPosterData,
                isGenerating: _store.isGeneratingPoster,
                onJobSelected: (job) async {
                  runInAction(() => _store.setGeneratingPoster(true));

                  final posterStore = inject<PosterCreationStore>();
                  await posterStore.selectJob(job);

                  runInAction(() {
                    _store.setGeneratingPoster(false);
                    if (posterStore.currentPosterData != null) {
                      _store.setSelectedPosterData(
                        posterStore.currentPosterData,
                      );
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
