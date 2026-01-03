import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/presentation/widgets/device/phone_view/store/phone_view_store.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../domain/entities/mirror_session.dart';
import '../../../global_stores/mirroring_store.dart';
import '../../../widgets/common/loading_view.dart';
import '../../../widgets/common/error_view.dart';
import '../../../widgets/common/connection_lost_view.dart';
import '../native_video_decoder/native_video_decoder.dart';
import 'widgets/mirror_navigation_bar.dart';
import 'widgets/drag_overlay_view.dart';
import 'widgets/push_progress_view.dart';

/// A widget that displays a mirroring view of a phone screen.
///
/// This widget handles:
/// - Video stream rendering
/// - User input delegation to MirroringStore
/// - Visibility detection for performance optimization
/// - File drag and drop
///
/// All business logic and state management is handled by [MirroringStore].
class PhoneView extends StatefulWidget {
  final String serial;
  final BoxFit fit;
  final bool isFloating;
  final FocusNode? focusNode;

  const PhoneView({
    super.key,
    required this.serial,
    this.fit = BoxFit.contain,
    this.isFloating = false,
    this.focusNode,
  });

  @override
  State<PhoneView> createState() => _PhoneViewState();
}

class _PhoneViewState extends State<PhoneView> {
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
          child: DropTarget(
            onDragEntered: (_) => _store.setDragging(widget.serial, true),
            onDragExited: (_) => _store.setDragging(widget.serial, false),
            onDragDone: (details) async {
              _store.setDragging(widget.serial, false);
              final paths = details.files.map((f) => f.path).toList();
              await _store.uploadFiles(widget.serial, paths);
            },
            child: Stack(
              children: [
                _buildContent(_store.session, isFloating),
                _buildDragOverlay(),
                _buildPushProgress(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(MirrorSession? session, bool isFloating) {
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
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: widget.isFloating
            ? (event) => _store.handleKeyboardEvent(widget.serial, event)
            : null,
        child: SizedBox(
          width: session.width.toDouble(),
          height: session.height.toDouble() + UIConstants.navigationBarHeight,
          child: _buildVideoWithNavigation(session),
        ),
      ),
    );
  }

  Widget _buildVideoWithNavigation(MirrorSession session) {
    return Column(
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
            child: Observer(
              builder: (context) {
                return NativeVideoDecoder(
                  key: Key('decoder_${widget.serial}'),
                  streamUrl: session.videoUrl,
                  nativeWidth: session.width,
                  nativeHeight: session.height,
                  service: session.decoderService,
                  fit: widget.fit,
                  isVisible: _store.isVisible,
                  onError: (error) =>
                      _store.setDecoderError(widget.serial, error),
                );
              },
            ),
          ),
        ),
        MirrorNavigationBar(store: _store, isEnabled: widget.isFloating),
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
        return const DragOverlayView();
      },
    );
  }

  Widget _buildPushProgress() {
    return Observer(
      builder: (_) {
        final isPushing = _store.isPushingFile;
        if (!isPushing) return const SizedBox.shrink();
        return const PushProgressView();
      },
    );
  }
}
