import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/core/utils/android_key_codes.dart';
import 'package:scraki/domain/entities/mirror_session.dart';
import 'package:scraki/presentation/stores/phone_view_store.dart';
import 'package:scraki/core/utils/logger.dart';
import 'native_video_decoder.dart';

/// A widget that displays a mirroring view of a phone screen and handles input events.
class PhoneView extends StatefulWidget {
  /// The ADB serial of the device to mirror.
  final String serial;

  /// How to fit the video stream within the layout.
  final BoxFit fit;

  /// Whether this view is specifically for a floating window.
  final bool isFloating;

  const PhoneView({
    super.key,
    required this.serial,
    this.fit = BoxFit.contain,
    this.isFloating = false,
  });

  @override
  State<PhoneView> createState() => _PhoneViewState();
}

class _PhoneViewState extends State<PhoneView> {
  String? _streamUrl;
  int _nativeWidth = 1080;
  int _nativeHeight = 2336;
  bool _isLoading = true;
  String? _errorMessage;
  final FocusNode _focusNode = FocusNode();

  // Double tap detection
  DateTime? _lastTapTime;
  static const _doubleTapTimeout = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _startMirroring();
  }

  @override
  void dispose() {
    final store = getIt<PhoneViewStore>();
    store.setVisibility(widget.serial, false, isFloating: widget.isFloating);

    // Only stop mirroring if:
    // 1. This is NOT a floating view (don't kill mirroring from floating overlay)
    // 2. AND the serial is not currently floating (keep session alive for floating window)
    if (!widget.isFloating && store.floatingSerial != widget.serial) {
      store.stopMirroring(widget.serial);
    }
    super.dispose();
  }

  Future<void> _startMirroring() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      logger.i('[PhoneView] Starting mirroring for ${widget.serial}...');
      final store = getIt<PhoneViewStore>();
      final session = await store.startMirroring(widget.serial);
      logger.i(
        '[PhoneView] Received session URL: ${session.videoUrl} (${session.width}x${session.height})',
      );

      if (!mounted) return;

      setState(() {
        _streamUrl = session.videoUrl;
        _nativeWidth = session.width;
        _nativeHeight = session.height;
        _isLoading = false;
      });
    } catch (e) {
      logger.e('[PhoneView] ERROR starting mirroring', error: e);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _onDecoderError(String error) {
    logger.e('[PhoneView] Decoder error: $error');
    if (!mounted) return;
    setState(() {
      _errorMessage = 'Decoder error: $error';
    });
  }

  void _handleDoubleTap() {
    logger.i(
      '[PhoneView] Double tap detected! Toggling floating window for ${widget.serial}',
    );
    getIt<PhoneViewStore>().toggleFloating(widget.serial);
  }

  void _handlePointer(PointerEvent event, int action) {
    // Request focus on tap to enable keyboard input
    if (action == 0 && !_focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
    }
    _onInput(event, action, _nativeWidth, _nativeHeight);
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _onScroll(event, _nativeWidth, _nativeHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = getIt<PhoneViewStore>();

    return Observer(
      builder: (_) {
        final session = store.activeSessions[widget.serial];

        // Accessing these ensures the Observer is always active
        final isFloating = store.floatingSerial == widget.serial;

        return VisibilityDetector(
          key: Key(
            'visibility_${widget.isFloating ? 'float' : 'grid'}_${widget.serial}',
          ),
          onVisibilityChanged: (info) {
            final isVisible = info.visibleFraction > 0.05;
            store.setVisibility(
              widget.serial,
              isVisible,
              isFloating: widget.isFloating,
            );
          },
          child: _buildContent(context, store, session, isFloating),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PhoneViewStore store,
    MirrorSession? session,
    bool isFloating,
  ) {
    final theme = Theme.of(context);
    // If this is the grid view AND the device is currently floating, show a placeholder
    if (!widget.isFloating && isFloating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.picture_in_picture,
              size: 48,
              color: Colors.white24,
            ),
            const SizedBox(height: 8),
            const Text(
              'Floating Mode',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            TextButton(
              onPressed: _handleDoubleTap,
              child: const Text('Bring Back'),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 32, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              'Mirroring Failed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startMirroring,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading && session == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to device...'),
          ],
        ),
      );
    }

    if (session == null && _errorMessage == null) {
      return const Center(child: Text('Initializing session...'));
    }

    final displayUrl = session?.videoUrl ?? _streamUrl;
    if (displayUrl == null && _errorMessage == null) {
      return const Center(child: Text('Waiting for stream URL...'));
    }

    return FittedBox(
      fit: widget.fit,
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          final action = (event is KeyDownEvent)
              ? 0
              : (event is KeyUpEvent)
              ? 1
              : -1;
          if (action != -1) {
            final isModified =
                HardwareKeyboard.instance.isMetaPressed ||
                HardwareKeyboard.instance.isControlPressed;

            // Handle Key Combinations
            if (isModified && action == 0) {
              if (event.logicalKey == LogicalKeyboardKey.keyV) {
                _handlePaste();
                return;
              }
              // Other shortcuts (A, C, X, Z) will be handled by regular _onKey with metaState
            }

            _onKey(event.logicalKey.keyId, action, _getAndroidMetaState());
          }
        },
        child: SizedBox(
          width: (session?.width ?? _nativeWidth).toDouble(),
          height: (session?.height ?? _nativeHeight).toDouble() + 140,
          child: DropTarget(
            onDragEntered: (details) {
              store.setDragging(widget.serial, true);
            },
            onDragExited: (details) {
              store.setDragging(widget.serial, false);
            },
            onDragDone: (details) async {
              store.setDragging(widget.serial, false);
              final paths = details.files.map((f) => f.path).toList();
              await store.uploadFiles(widget.serial, paths);
            },
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Listener(
                        onPointerDown: (e) => _handlePointer(e, 0),
                        onPointerUp: (e) => _handlePointer(e, 1),
                        onPointerMove: (e) => _handlePointer(e, 2),
                        onPointerSignal: _handleScroll,
                        child: NativeVideoDecoder(
                          key: Key('decoder_${widget.serial}'),
                          streamUrl: displayUrl!,
                          nativeWidth: session?.width ?? _nativeWidth,
                          nativeHeight: session?.height ?? _nativeHeight,
                          service: session!.decoderService,
                          fit: widget.fit,
                          onError: _onDecoderError,
                        ),
                      ),
                    ),
                    _buildNavigationBar(),
                  ],
                ),
                Observer(
                  builder: (_) {
                    final isDragging =
                        store.isDraggingFile[widget.serial] ?? false;
                    if (!isDragging) return const SizedBox.shrink();

                    return Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            color: theme.colorScheme.primaryContainer
                                .withOpacity(0.7),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      48,
                                    ), // Increased padding
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.3),
                                          blurRadius: 40,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.file_copy_rounded,
                                      size: 180, // Massive icon
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 48),
                                  Text(
                                    'Drop Files to Sync',
                                    style: theme.textTheme.displayMedium
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 80, // Forced large font
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Files will be copied to /sdcard/Download',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onPrimaryContainer
                                              .withOpacity(0.7),
                                          fontSize: 40, // Forced large font
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Observer(
                  builder: (_) {
                    final isPushing =
                        store.isPushingFile[widget.serial] ?? false;
                    if (!isPushing) return const SizedBox.shrink();
                    return Positioned(
                      top: 40, // More margin
                      left: 40,
                      right: 40,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  strokeWidth: 6,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Text(
                                'Pushing files to phone...',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    final theme = Theme.of(context);
    return Container(
      height: 140,
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow),
      child: Column(
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(
                  Icons.arrow_back_ios_new_rounded,
                  AndroidKeyCodes.kBack,
                ),
                _buildNavButton(
                  Icons.circle_outlined,
                  AndroidKeyCodes.kHome,
                  isPrimary: true,
                ),
                _buildNavButton(
                  Icons.crop_square_rounded,
                  AndroidKeyCodes.kAppSwitch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, int keyCode, {bool isPrimary = false}) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Send Down then Up for a full click
          getIt<PhoneViewStore>().sendKey(widget.serial, keyCode, 0);
          Future.delayed(const Duration(milliseconds: 50), () {
            getIt<PhoneViewStore>().sendKey(widget.serial, keyCode, 1);
          });
        },
        borderRadius: BorderRadius.circular(40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: isPrimary
                ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: isPrimary
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            size: isPrimary ? 54 : 48,
          ),
        ),
      ),
    );
  }

  void _onKey(int keyId, int action, int metaState) {
    final key = LogicalKeyboardKey.findKeyByKeyId(keyId);
    if (key != null) {
      final androidCode = AndroidKeyCodes.getKeyCode(key);
      if (androidCode != AndroidKeyCodes.kUnknown) {
        getIt<PhoneViewStore>().sendKey(
          widget.serial,
          androidCode,
          action,
          metaState: metaState,
        );
      }
    }
  }

  int _getAndroidMetaState() {
    int meta = 0;
    if (HardwareKeyboard.instance.isShiftPressed) {
      meta |= AndroidKeyCodes.kMetaShiftOn;
    }
    if (HardwareKeyboard.instance.isControlPressed) {
      meta |= AndroidKeyCodes.kMetaCtrlOn;
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      meta |= AndroidKeyCodes.kMetaAltOn;
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      meta |=
          AndroidKeyCodes.kMetaCtrlOn; // Map Cmd to Ctrl for Android shortcuts
    }
    return meta;
  }

  void _onScroll(PointerScrollEvent event, int width, int height) {
    getIt<PhoneViewStore>().handleScrollEvent(
      widget.serial,
      event,
      width,
      height,
    );
  }

  void _onInput(PointerEvent event, int action, int width, int height) {
    // Double tap detection
    if (action == 0) {
      // PointerDown
      final now = DateTime.now();
      if (_lastTapTime != null &&
          now.difference(_lastTapTime!) < _doubleTapTimeout) {
        _handleDoubleTap();
        _lastTapTime = null; // Reset
      } else {
        _lastTapTime = now;
      }
    }

    getIt<PhoneViewStore>().handlePointerEvent(
      widget.serial,
      event,
      action,
      width,
      height,
    );
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      logger.i(
        '[PhoneView] Pasting text to ${widget.serial}: ${text.length} chars',
      );
      // Option 1: Set clipboard and paste (Best for large text)
      getIt<PhoneViewStore>().setClipboard(widget.serial, text, paste: true);

      // Option 2: Inject text directly (Alternative)
      // getIt<PhoneViewStore>().sendText(widget.serial, text);
    }
  }
}
