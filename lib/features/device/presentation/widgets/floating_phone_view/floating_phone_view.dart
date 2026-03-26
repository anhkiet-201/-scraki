import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/mixins/session_manager_store_mixin.dart';
import 'package:scraki/core/stores/device_manager_store.dart';
import 'package:scraki/features/poster/presentation/stores/poster_creation_store.dart';
import '../phone_view/phone_view.dart';
import 'widgets/floating_tool_box/floating_tool_box.dart';
import 'widgets/floating_window_header.dart';
import 'widgets/floating_resize_handle.dart';
import 'store/floating_phone_view_store.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'widgets/floating_tool_box/store/floating_tool_box_store.dart';

/// Widget hiển thị cửa sổ điện thoại nổi (Floating Window).
class FloatingPhoneView extends StatefulWidget {
  final String serial;
  final VoidCallback onClose;
  final Size parentSize;
  final PosterData? posterData;
  final bool isGenerating;
  final String? errorMessage;
  final void Function(PosterData)? onJobSelected;
  final VoidCallback? onRetry;

  const FloatingPhoneView({
    super.key,
    required this.serial,
    required this.onClose,
    required this.parentSize,
    this.posterData,
    this.isGenerating = false,
    this.errorMessage,
    this.onJobSelected,
    this.onRetry,
  });

  @override
  State<FloatingPhoneView> createState() => _FloatingPhoneViewState();
}

class _FloatingPhoneViewState extends State<FloatingPhoneView>
    with SessionManagerStoreMixin {
  late final FloatingPhoneViewStore _store;
  late final DeviceManagerStore _deviceManagerStore;
  late final FloatingToolBoxStore _toolBoxStore;

  final GlobalKey<FloatingToolBoxState> _toolBoxKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _store = FloatingPhoneViewStore(widget.parentSize);
    _deviceManagerStore = inject<DeviceManagerStore>();
    _toolBoxStore = FloatingToolBoxStore();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  String get _deviceTitle {
    try {
      return _deviceManagerStore.devices
          .firstWhere((d) => d.serial == widget.serial)
          .modelName;
    } catch (_) {
      return widget.serial;
    }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 0,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: _store.width,
                      height: _store.height,
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.65),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          FloatingWindowHeader(
                            title: _deviceTitle,
                            onClose: widget.onClose,
                            onDragUpdate: (details) {
                              runInAction(() {
                                final newPosition = _store.getClampedPosition(
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
                                    color: Colors.transparent,
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
                                final delta = details.delta.dx + details.delta.dy;
                                double maxAllowedWidth = 1200.0;
                                if (!widget.parentSize.isEmpty) {
                                  final maxWidthByX = widget.parentSize.width - _store.position.dx;
                                  final maxHeightAvailable = widget.parentSize.height - _store.position.dy - 52;
                                  final maxWidthByY = maxHeightAvailable * aspectRatio;
                                  maxAllowedWidth = [maxWidthByX, maxWidthByY, 1200.0].reduce((a, b) => a < b ? a : b);
                                }
                                final newWidth = (_store.width + delta).clamp(240.0, maxAllowedWidth);
                                final newHeight = (newWidth / aspectRatio) + 48 + 16;
                                _store.updateDimensions(newWidth, newHeight);
                                _store.updatePosition(_store.getClampedPosition(_store.position, widget.parentSize));
                              });
                            },
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
                store: _toolBoxStore,
                availableSpace: _store.getToolBoxAvailableSpace(widget.parentSize),
                posterData: widget.posterData,
                isGenerating: widget.isGenerating,
                errorMessage: widget.errorMessage,
                onJobSelected: (job) => widget.onJobSelected?.call(job),
                onRetry: widget.onRetry,
              ),
            ],
          ),
        );
      },
    );
  }
}
