import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/constants/ui_constants.dart';
import 'package:scraki/core/widgets/connection_lost_view.dart';
import 'package:scraki/core/widgets/error_view.dart';
import 'package:scraki/core/widgets/loading_view.dart';
import 'package:scraki/features/device/domain/entities/mirror_session.dart';
import 'package:scraki/features/device/presentation/widgets/native_video_decoder/native_video_decoder.dart';
import 'package:scraki/features/device/presentation/widgets/phone_view/store/phone_view_store.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'widgets/mirror_navigation_bar.dart';
import 'widgets/device_task_overlay.dart';
import 'widgets/drag_overlay_view.dart';

/// A widget that displays a mirroring view of a phone screen.
///
/// This widget handles:
/// - Video stream rendering
/// - User input delegation to SessionManagerStore
/// - Visibility detection for performance optimization
/// - File drag and drop
///
/// All business logic and state management is handled by [SessionManagerStore].
import 'dart:io';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';

class PhoneView extends StatefulWidget {
  final String serial;
  final BoxFit fit;
  final bool isFloating;
  final FocusNode? focusNode;
  final Future<File?> Function(PosterData)? onPosterDropped;

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
          child: DropRegion(
            formats: Formats.standardFormats,
            onDropOver: (event) {
              if (!widget.isFloating && !_store.isOnDevicesTab) {
                return DropOperation.none;
              }
              if (_store.isBlockedByFloating) return DropOperation.none;

              // Mặc định là dragging file bình thường
              _store.setDragging(widget.serial, true);

              // Kiểm tra xem có file APK nào đang được kéo không (Xử lý async)
              for (final item in event.session.items) {
                item.dataReader?.getSuggestedName().then((name) {
                  if (mounted &&
                      name != null &&
                      name.toLowerCase().endsWith('.apk')) {
                    _store.setDragging(widget.serial, true, isApk: true);
                  }
                });
              }

              return DropOperation.copy;
            },
            onDropLeave: (_) => _store.setDragging(widget.serial, false),
            onPerformDrop: (event) async {
              _store.setDragging(widget.serial, false);

              // Guard 1: Không cho phép drop khi đang ở tab khác
              if (!widget.isFloating && !_store.isOnDevicesTab) return;

              // Guard 2: Nếu floating đang mở, chỉ floating view mới được nhận drop;
              // grid view bên dưới bị block.
              if (_store.isBlockedByFloating) return;

              // Collect file paths từ getValue callbacks.
              // getValue callback fires synchronously trên Windows → completer
              // resolve NGAY trong vòng lặp → await bên dưới return gần như instant,
              // không block platform thread đáng kể.
              final paths = <String>[];
              final completer = Completer<void>();
              var pending = 0;

              void tryComplete() {
                pending--;
                if (pending == 0) completer.complete();
              }

              for (final item in event.session.items) {
                final reader = item.dataReader;
                if (reader != null && reader.canProvide(Formats.fileUri)) {
                  pending++;
                  reader.getValue<Uri>(Formats.fileUri, (Uri? uri) {
                    if (uri != null) paths.add(uri.toFilePath());
                    tryComplete();
                  });
                }
              }

              if (pending == 0) return; // không có file nào

              // Chờ tất cả callbacks → gần như instant vì getValue fires synchronously
              await completer.future;

              if (paths.isNotEmpty) {
                // ignore: discarded_futures — uploadFiles chạy background, không block UI
                _store.uploadFiles(widget.serial, paths);
              }
            },
            child: DragTarget<PosterData>(
              onWillAcceptWithDetails: (details) {
                // Guard 1: Từ chối nếu không ở tab Devices
                if (!widget.isFloating && !_store.isOnDevicesTab) return false;

                // Guard 2: Từ chối nếu floating đang che grid
                if (_store.isBlockedByFloating) return false;

                _store.setDragging(widget.serial, true);
                return true;
              },
              onLeave: (data) {
                _store.setDragging(widget.serial, false);
              },
              onAcceptWithDetails: (details) async {
                _store.setDragging(widget.serial, false);
                if (widget.onPosterDropped != null) {
                  final file = await widget.onPosterDropped!(details.data);
                  if (mounted && file != null) {
                    await _store.uploadFiles(widget.serial, [file.path]);
                  }
                }
              },
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
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: widget.isFloating
            ? (event) => _store.handleKeyboardEvent(widget.serial, event)
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
        return DragOverlayView(store: _store);
      },
    );
  }

}
