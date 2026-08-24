import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scrcpy_flutter_plugin/scrcpy_flutter_plugin.dart' as plugin;
import 'package:scraki/core/constants/ui_constants.dart';
import 'package:scraki/core/widgets/connection_lost_view.dart';
import 'package:scraki/core/widgets/error_view.dart';
import 'package:scraki/core/widgets/loading_view.dart';
import 'package:scraki/features/device/domain/entities/mirror_session.dart';
import 'package:scraki/features/device/presentation/widgets/phone_view/store/phone_view_store.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'widgets/mirror_navigation_bar.dart';
import 'widgets/device_task_overlay.dart';
import 'widgets/drag_overlay_view.dart';
import 'package:scraki/core/mixins/app_auth_store_mixin.dart';

/// A widget that displays a mirroring view of a phone screen.
///
/// This widget handles:
/// - Video stream rendering
/// - User input delegation to SessionManagerStore
/// - Visibility detection for performance optimization
/// - File drag and drop
///
/// All business logic and state management is handled by [SessionManagerStore].
import 'package:scraki/features/poster/domain/entities/poster_data.dart';

class PhoneView extends StatefulWidget {
  final String serial;
  final BoxFit fit;
  final bool isFloating;
  final FocusNode? focusNode;
  final PosterDropHandler? onPosterDropped;

  const PhoneView({
    super.key,
    required this.serial,
    this.fit = BoxFit.contain,
    this.isFloating = false,
    this.focusNode,
    this.onPosterDropped,
  });

  @override
  State<PhoneView> createState() => _PhoneViewState();
}

class _PhoneViewState extends State<PhoneView> with AppAuthStoreMixin {
  late final FocusNode _focusNode;
  late final PhoneViewStore _store;

  @override
  void initState() {
    _focusNode = widget.focusNode ?? FocusNode();
    _store = PhoneViewStore(widget.serial, widget.isFloating);
    super.initState();
    if (widget.focusNode != null && _store.isFloatingView) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final isFloating = _store.floatingSerial == widget.serial;
        return VisibilityDetector(
          key: Key(
            'visibility_${widget.isFloating ? 'float' : 'grid'}_${widget.serial}',
          ),
          onVisibilityChanged: (info) {
            if (!mounted) return;
            final isVisible =
                info.visibleFraction > UIConstants.visibilityThreshold;
            _store.setVisibility(
              widget.serial,
              isVisible,
              isFloating: widget.isFloating,
            );
          },
          child: DropRegion(
            formats: Formats.standardFormats,
            onDropOver: _store.handleDropOver,
            onDropLeave: (_) => _store.handleDropLeave(),
            onPerformDrop: _store.handlePerformDrop,
            child: DragTarget<PosterData>(
              onWillAcceptWithDetails: (_) => _store.handleInternalDragWillAccept(),
              onLeave: (_) => _store.handleInternalDragLeave(),
              onAcceptWithDetails:
                  (details) => _store.handleInternalDragAccept(
                    details.data,
                    widget.onPosterDropped,
                  ),
              builder: (context, candidateData, rejectedData) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(child: _buildContent(isFloating)),
                    _buildDragOverlay(),
                    DeviceTaskOverlay(store: _store),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isFloating) {
    return Observer(
      builder: (_) {
        final session = _store.session;
        // Placeholder when device is floating in another window
        if (!widget.isFloating && isFloating) {
          return _buildPlaceholder();
        }

        // Connection lost
        if (_store.hasLostConnection) {
          return ConnectionLostView(
            onReconnect: _store.startMirroring,
            isConnecting: _store.isConnecting,
          );
        }

        // Error state
        final errorMessage = _store.error;
        if (errorMessage != null) {
          return ErrorView(
            title: 'Mirroring Failed',
            message: errorMessage,
            onRetry: _store.startMirroring,
          );
        }

        // Loading or no session
        if (session == null) {
          final isLoading = _store.isLoading;
          return LoadingView(
            message: isLoading
                ? 'Connecting to device...'
                : 'Initializing session...',
          );
        }

        return _buildMirrorView(session);
      },
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_in_picture, size: 48, color: Colors.white24),
          const SizedBox(height: 8),
          const Text(
            'Floating Mode',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          TextButton(
            onPressed: () => _store.toggleFloating(null),
            child: const Text('Bring Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildMirrorView(MirrorSession session) {
    return FittedBox(
      fit: widget.fit,
      alignment: Alignment.center,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: widget.isFloating
            ? (node, event) {
                _store.handleKeyboardEvent(widget.serial, event);
                return KeyEventResult.handled;
              }
            : null,
        child: SizedBox(
          width: session.width.toDouble(),
          height:
              session.height.toDouble() +
              (_store.isFloating
                  ? UIConstants.floatingNavigationBarHeight
                  : UIConstants.gridNavigationBarHeight),
          child: _buildVideoWithNavigation(session),
        ),
      ),
    );
  }

  Widget _buildVideoWithNavigation(MirrorSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Listener(
            onPointerDown: widget.isFloating
                ? (e) => _handlePointer(e, 0, session)
                : (e) => _handleDoubleTapOnly(e),
            onPointerUp: widget.isFloating
                ? (e) => _handlePointer(e, 1, session)
                : null,
            onPointerMove: widget.isFloating
                ? (e) => _handlePointer(e, 2, session)
                : null,
            onPointerSignal: widget.isFloating
                ? (event) {
                    if (event is PointerScrollEvent) {
                      _store.handleScrollEvent(
                        widget.serial,
                        event,
                        session.width,
                        session.height,
                      );
                    }
                  }
                : null,
            child: Builder(
              builder: (context) {
                final controller = _store.controller;
                if (controller == null) {
                  return Container(color: Colors.black);
                }
                return ExcludeFocus(
                  excluding: !widget.isFloating,
                  child: plugin.ScrcpyTextureWidget(
                    key: Key('decoder_${widget.serial}'),
                    controller: controller,
                    inputHandler: const _NoOpInputHandler(),
                  ),
                );
              },
            ),
          ),
        ),
        MirrorNavigationBar(store: _store, isFloating: widget.isFloating),
      ],
    );
  }

  void _handlePointer(PointerEvent event, int action, MirrorSession session) {
    if (!mounted) return;

    // Request focus on pointer event
    if (!_focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
    }

    // Check for double tap only in grid view (to toggle floating)
    // In floating mode, double-tap should be sent to the device
    if (!widget.isFloating && action == 0) {
      final isDoubleTap = _store.checkDoubleTap(widget.serial);
      if (isDoubleTap) return;
    }

    // Delegate to store
    _store.handlePointerEvent(
      widget.serial,
      event,
      action,
      session.width,
      session.height,
    );
  }

  void _handleDoubleTapOnly(PointerEvent event) {
    if (!mounted) return;

    // Check for double tap to toggle floating
    final isDoubleTap = _store.checkDoubleTap(widget.serial);
    if (isDoubleTap) {
      // No need to do anything else, checkDoubleTap already toggles floating
    }
  }

  Widget _buildDragOverlay() {
    return Observer(
      builder: (_) {
        final isDragging = _store.isDraggingFile;
        if (!isDragging) return const SizedBox.shrink();

        if (!appAuthStore.isAuthenticated) {
          return ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.85, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, childWidget) {
                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: ((scale - 0.85) / 0.15).clamp(0.0, 1.0),
                              child: childWidget,
                            ),
                          );
                        },
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 280),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Glow Lock Icon
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Color(0xFFFCA5A5),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Title
                              const Text(
                                'Tính năng bị khóa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              // Description
                              const Text(
                                'Kéo thả tệp yêu cầu thiết bị được xác thực.',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return DragOverlayView(store: _store);
      },
    );
  }

}

class _NoOpInputHandler extends plugin.ScrcpyInputHandler {
  const _NoOpInputHandler();

  @override
  KeyEventResult handleKeyEvent(FocusNode focusNode, KeyEvent event, plugin.ScrcpyController controller) => KeyEventResult.ignored;

  @override
  void handlePointerDown(PointerDownEvent event, BoxConstraints constraints, plugin.ScrcpyController controller, FocusNode focusNode) {}

  @override
  void handlePointerMove(PointerMoveEvent event, BoxConstraints constraints, plugin.ScrcpyController controller) {}

  @override
  void handlePointerUp(PointerUpEvent event, BoxConstraints constraints, plugin.ScrcpyController controller) {}

  @override
  void handlePointerCancel(PointerCancelEvent event, BoxConstraints constraints, plugin.ScrcpyController controller) {}

  @override
  void handlePointerScroll(PointerScrollEvent event, BoxConstraints constraints, plugin.ScrcpyController controller) {}
}
