import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/video_overlay_item/video_overlay_item.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/image_overlay_item/image_overlay_item.dart';
import 'package:scraki/features/video_poster/presentation/widgets/controls/floating_glass_controls.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/media_library_panel.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/text_properties_panel.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/batch_video_panel.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/image_library_panel.dart';

/// Nav tab index constants
const int _kNavMedia = 0;
const int _kNavText = 1;
const int _kNavImage = 2;

class VideoPosterPlaygroundPage extends StatefulWidget {
  const VideoPosterPlaygroundPage({super.key});

  @override
  State<VideoPosterPlaygroundPage> createState() =>
      _VideoPosterPlaygroundPageState();
}

class _VideoPosterPlaygroundPageState extends State<VideoPosterPlaygroundPage> {
  late final VideoPosterStore store;

  @override
  void initState() {
    super.initState();
    store = GetIt.I<VideoPosterStore>();
  }

  @override
  void dispose() {
    // CRITICAL: Dispose the player to prevent "Callback invoked after it has been deleted"
    // crashes on hot restart or navigation.
    store.disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        cardColor: const Color(0xFF1A1A1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          surface: Color(0xFF1A1A1A),
          onSurface: Colors.white,
        ),
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space, control: true): () {
            if (store.player.state.position >= store.player.state.duration &&
                store.player.state.duration > Duration.zero) {
              store.seekProject(Duration.zero);
              store.player.play();
            } else {
              store.player.playOrPause();
            }
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Column(
              children: [
                _buildModernToolbar(),
                Expanded(
                  child: Observer(
                    builder: (context) {
                      return Stack(
                        children: [
                          // Base layout
                          Row(
                            children: [
                              // Left nav bar
                              _buildUnifiedNavBar(),

                              // Left panel (media library or text properties)
                              SizedBox(
                                width: 300,
                                child: Observer(
                                  builder: (_) {
                                    if (store.activeNavIndex == _kNavText) {
                                      return TextPropertiesPanel(store: store);
                                    } else if (store.activeNavIndex ==
                                        _kNavImage) {
                                      return ImageLibraryPanel(store: store);
                                    } else {
                                      return MediaLibraryPanel(
                                        store: store,
                                        onVideoTap: store.playVideoAtIndex,
                                      );
                                    }
                                  },
                                ),
                              ),

                              // Main workspace
                              Expanded(
                                child: Observer(
                                  builder: (context) => Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black,
                                          child: Center(
                                            child: _buildInteractivePreview(),
                                          ),
                                        ),
                                      ),

                                      // Floating player controls
                                      Positioned(
                                        bottom: 40,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: FloatingGlassControls(
                                            isPlaying: store.isPlaying,
                                            position: store.position,
                                            duration: store.duration,
                                            onPlayPause: () {
                                              if (store.isPlaying) {
                                                store.player.pause();
                                              } else {
                                                store.player.play();
                                              }
                                            },
                                            onSeek: (p) => store.seekProject(p),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Right panel (Batch Video Creation - base)
                              SizedBox(
                                width: 280,
                                // Need to provide a key to isolate states from the overlay version
                                child: BatchVideoPanel(
                                  key: const ValueKey('panel_base'),
                                  store: store,
                                ),
                              ),
                            ],
                          ),

                          // Full-screen overlay for Batch Creating Mode
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            top: 0,
                            bottom: 0,
                            // Stretch to full width of the Stack when active
                            // When inactive, move entirely to the right
                            left: store.isBatchCreating
                                ? 0
                                : MediaQuery.of(context).size.width,
                            right: store.isBatchCreating
                                ? 0
                                : -MediaQuery.of(context).size.width,
                            child: Material(
                              elevation: 16,
                              child: BatchVideoPanel(
                                key: const ValueKey('panel_overlay'),
                                store: store,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Toolbar ───────────────────────────────────────────────────────────────

  Widget _buildModernToolbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F).withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 60),
          const Text(
            'SCRAKI',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'STUDIO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Observer(
            builder: (_) {
              return Row(
                children: [
                   _buildModeToggle(),
                   const SizedBox(width: 12),
                  _buildActionButton('DỰ ÁN MỚI', Icons.add_rounded, () {
                    store.resetProject();
                  }),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Observer(
      builder: (_) {
        final isPreview = store.isPreviewMode;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeOption(
                label: 'CHỈNH SỬA',
                icon: Icons.edit_note_rounded,
                isActive: !isPreview,
                onTap: () {
                  if (isPreview) store.togglePreviewMode();
                },
              ),
              _buildModeOption(
                label: 'XEM TRƯỚC',
                icon: Icons.play_circle_outline_rounded,
                isActive: isPreview,
                onTap: () {
                  if (!isPreview) store.togglePreviewMode();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeOption({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.white30,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.white30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isOutline = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : Colors.white10,
          border: isOutline ? Border.all(color: Colors.white10) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Nav Bar ──────────────────────────────────────────────────────────────

  Widget _buildUnifiedNavBar() {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 80),
          _buildNavIcon(_kNavMedia, Icons.inventory_2_outlined, 'MEDIA'),
          const SizedBox(height: 4),
          _buildNavIcon(_kNavText, Icons.text_fields_rounded, 'TEXT'),
          const SizedBox(height: 4),
          _buildNavIcon(_kNavImage, Icons.image_outlined, 'IMAGES'),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon, String label) {
    return Observer(
      builder: (context) {
        final active = store.activeNavIndex == index;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: InkWell(
            onTap: () => store.setActiveNavIndex(index),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF6366F1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: active ? Colors.white : Colors.white38,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.white : Colors.white24,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Interactive Preview ──────────────────────────────────────────────────

  Widget _buildInteractivePreview() {
    return _ImageDropZone(
      store: store,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    // Video Preview
                    Observer(
                      warnWhenNoObservables: false,
                      builder: (context) {
                        if (store.sourceVideoPaths.isEmpty) {
                          return Container(
                            color: Colors.black,
                            child: const Center(
                              child: Text(
                                'No Video Selected',
                                style: TextStyle(color: Colors.white24),
                              ),
                            ),
                          );
                        }
                        return Video(
                          controller: store.videoController,
                          fit: BoxFit.cover,
                          controls: (state) => const SizedBox.shrink(),
                        );
                      },
                    ),

                    // Virtual canvas for free text overlays (720x1280)
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        clipBehavior: Clip.none,
                        child: SizedBox(
                          width: 720,
                          height: 1280,
                          child: RepaintBoundary(
                            key: store.previewKey,
                            child: Observer(
                              builder: (context) {
                                const virtualConstraints = BoxConstraints(
                                  maxWidth: 720,
                                  maxHeight: 1280,
                                );

                                return GestureDetector(
                                  // Deselect when tapping blank area
                                  onTap: () {
                                    store.selectCustomText(null);
                                    store.selectCustomImage(null);
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Transparent background — shows video below
                                      Positioned.fill(
                                        child: DragTarget<Map<String, dynamic>>(
                                          onAcceptWithDetails: (details) {
                                            final renderBox =
                                                store.previewKey.currentContext
                                                        ?.findRenderObject()
                                                    as RenderBox?;
                                            if (renderBox != null) {
                                              final localOffset = renderBox
                                                  .globalToLocal(
                                                    details.offset,
                                                  );

                                              // DragDraggable in ImageLibraryPanel had 100x100 size for feedback
                                              // Adjust center offset by half size
                                              final adjustedX =
                                                  (localOffset.dx + 50) /
                                                  renderBox.size.width;
                                              final adjustedY =
                                                  (localOffset.dy + 50) /
                                                  renderBox.size.height;

                                              final x = adjustedX.clamp(
                                                0.0,
                                                1.0,
                                              );
                                              final y = adjustedY.clamp(
                                                0.0,
                                                1.0,
                                              );

                                              final data = details.data;
                                              store.addCustomImage(
                                                data['url'] as String,
                                                x,
                                                y,
                                                isGif: data['isGif'] as bool,
                                              );
                                            }
                                          },
                                          builder:
                                              (
                                                context,
                                                candidateData,
                                                rejectedData,
                                              ) {
                                                return Container(
                                                  color:
                                                      candidateData.isNotEmpty
                                                      ? Colors.white.withValues(alpha: 0.1)
                                                      : Colors.transparent,
                                                );
                                              },
                                        ),
                                      ),

                                      // Custom Image Overlays
                                      if (!store.isHidingImagesForCapture)
                                        ...store.customImages.where((image) {
                                          if (!store.isPreviewMode) return true;
                                          final pos = store.position.inMilliseconds / 1000.0;
                                          if (pos < image.startTime) return false;
                                          if (image.endTime != null && pos > image.endTime!) {
                                            return false;
                                          }
                                          return true;
                                        }).map(
                                          (image) => ImageOverlayItem(
                                            key: ValueKey(image.id),
                                            id: image.id,
                                            imageUrl: image.imageUrl,
                                            isGif: image.isGif,
                                            x: image.x,
                                            y: image.y,
                                            width: image.width,
                                            height: image.height,
                                            rotation: image.rotation,
                                            constraints: virtualConstraints,
                                            isSelected:
                                                store.selectedCustomImageId ==
                                                image.id,
                                            onPositionUpdate: (id, x, y) =>
                                                store.updateCustomImagePosition(
                                                    id, x, y),
                                            onSelect: store.selectCustomImage,
                                            onResize: (id, w, h) =>
                                                store.updateCustomImageSize(
                                                    id, w, h),
                                            borderColor: image.borderColor,
                                            borderWidth: image.borderWidth,
                                            borderRadius: image.borderRadius,
                                          ),
                                        ),

                                      // Free-form custom text overlays
                                      ...store.customTexts.where((text) {
                                          if (!store.isPreviewMode) return true;
                                          final pos = store.position.inMilliseconds / 1000.0;
                                          if (pos < text.startTime) return false;
                                          if (text.endTime != null && pos > text.endTime!) {
                                            return false;
                                          }
                                          return true;
                                        }).map(
                                        (text) {
                                          final isAnimated = text.isAnimated;
                                          return Observer(
                                            key: ValueKey('text_wrapper_${text.id}'),
                                            builder: (context) {
                                              final shouldHide = store.isHidingAnimatedTextsForCapture && isAnimated;
                                              
                                              return VideoOverlayItem(
                                                key: ValueKey(text.id),
                                                label: text.label,
                                                x: text.x,
                                                y: text.y,
                                                type: text.id,
                                                constraints: virtualConstraints,
                                                color: text.color,
                                                fontSize: text.fontSize,
                                                textHeight: text.textHeight,
                                                fontWeight: text.fontWeight,
                                                fontStyle: text.fontStyle,
                                                textAlign: text.textAlign,
                                                backgroundColor: text.backgroundColor,
                                                backgroundOpacity: text.backgroundOpacity,
                                                backgroundRadius: text.backgroundRadius,
                                                backgroundBorderColor: text.backgroundBorderColor,
                                                backgroundBorderWidth: text.backgroundBorderWidth,
                                                fontFamily: text.fontFamily,
                                                rotation: text.rotation,
                                                strokeColor: text.strokeColor,
                                                strokeWidth: text.strokeWidth,
                                                letterSpacing: text.letterSpacing,
                                                isSelected: store.selectedCustomTextId == text.id,
                                                opacity: shouldHide ? 0.0 : 1.0,
                                                captureKey: isAnimated ? store.getTextCaptureKey(text.id) : null,
                                                onPositionUpdate: (_, x, y) =>
                                                    store.updateCustomTextPosition(
                                                      text.id,
                                                      x,
                                                      y,
                                                      ),
                                                onSelect: (_) =>
                                                    store.selectCustomText(text.id),
                                                onResize: (_, size) =>
                                                    store.updateCustomTextFontSize(
                                                      text.id,
                                                      size,
                                                      ),
                                                onTextChange: (_, val) =>
                                                    store.updateCustomTextLabel(
                                                      text.id,
                                                      val,
                                                      ),
                                                // Animation props
                                                animationInType: text.animationInType,
                                                animationInDuration: text.animationInDuration,
                                                animationOutType: text.animationOutType,
                                                animationOutDuration: text.animationOutDuration,
                                                isPreviewMode: store.isPreviewMode,
                                                currentTime: store.position.inMilliseconds / 1000.0,
                                                startTime: text.startTime,
                                                endTime: text.endTime ?? (store.duration.inMilliseconds.toDouble()) / 1000.0,
                                                triggerPreviewCounter: store.animationPreviewCounters[text.id] ?? 0,
                                              );
                                            },
                                          );
                                        }),
                                  ],
                                ),
                              );
                            },
                          ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Drop Zone: nhận ảnh từ file + URL ───────────────────────────────────────

class _ImageDropZone extends StatefulWidget {
  final VideoPosterStore store;
  final Widget child;
  const _ImageDropZone({required this.store, required this.child});

  @override
  State<_ImageDropZone> createState() => _ImageDropZoneState();
}

class _ImageDropZoneState extends State<_ImageDropZone> {
  bool _isDragging = false;
  final _zoneFocus = FocusNode(); // focus vùng drop để nhận keyboard

  @override
  void initState() {
    super.initState();
    // Tự request focus để nhận Ctrl+V
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _zoneFocus.requestFocus(),
    );
  }

  @override
  void dispose() {
    _zoneFocus.dispose();
    super.dispose();
  }

  static const _imgExts = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp'];
  static const _videoExts = [
    '.mp4',
    '.mov',
    '.avi',
    '.mkv',
    '.webm',
    '.m4v',
    '.flv',
    '.wmv',
    '.3gp',
    '.ts',
  ];

  bool _isImgFile(String p) => _imgExts.any(p.toLowerCase().endsWith);
  bool _isVideoFile(String p) => _videoExts.any(p.toLowerCase().endsWith);

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      debugPrint('[PASTE] clipboard: $text');
      if (text.isEmpty) return;
      final url = _resolve(text);
      if (url.startsWith('http')) {
        debugPrint('[PASTE] -> adding: $url');
        widget.store.addCustomImage(
          url,
          0.5,
          0.5,
          isGif:
              url.toLowerCase().contains('.gif') ||
              url.toLowerCase().contains('giphy'),
        );
      } else {
        debugPrint('[PASTE] -> not a URL, ignoring');
      }
    } catch (e) {
      debugPrint('[PASTE] error: $e');
    }
  }

  // Fallback kiểm tra Magic bytes cho local file (nếu cần)

  String _resolve(String url) {
    try {
      final u = Uri.parse(url);
      final imgurl = u.queryParameters['imgurl'];
      if (imgurl != null && imgurl.isNotEmpty) {
        return Uri.decodeComponent(imgurl);
      }
    } catch (_) {}
    return url;
  }

  Future<void> _handleDropItem(DropItem item) async {
    final formats = item.dataReader?.getFormats(Formats.standardFormats);
    debugPrint('[DROP] Processing item with formats: $formats');
    final reader = item.dataReader;
    if (reader == null) return;

    // 1. Nếu kéo file vật lý từ desktop
    if (reader.canProvide(Formats.fileUri)) {
      reader.getValue<Uri>(Formats.fileUri, (Uri? uri) {
        if (uri != null) {
          final p = uri.toFilePath();
          debugPrint('[DROP] local file: $p');
          // Bỏ qua video — để MediaLibraryPanel xử lý
          if (_isVideoFile(p)) {
            debugPrint('[DROP] skipping video file in image zone: $p');
            return;
          }
          if (_isImgFile(p)) {
            widget.store.addCustomImage(
              p,
              0.5,
              0.5,
              isGif: p.toLowerCase().endsWith('.gif'),
            );
          }
          // Bỏ qua .url / .webloc và các định dạng khác
        }
      }, onError: (e) => debugPrint('[DROP] err: $e'));
      return;
    }

    // 2. Kéo ảnh từ browser (Chrome/Edge) gửi HTML (có thẻ img)
    if (reader.canProvide(Formats.htmlText)) {
      reader.getValue<String>(Formats.htmlText, (String? html) {
        if (html != null) {
          String decodedHtml = html;
          // Phát hiện lỗi UTF-8 bytes bị ép kiểu nhầm thành UTF-16LE String (thường tạo ra các ký tự CJK)
          if (html.isNotEmpty && html.codeUnitAt(0) > 255) {
            try {
              final encoded = Uint8List(html.length * 2);
              for (int i = 0; i < html.length; i++) {
                final codeUnit = html.codeUnitAt(i);
                encoded[i * 2] = codeUnit & 0xFF; // Xử lý Little Endian Byte 1
                encoded[i * 2 + 1] =
                    codeUnit >> 8; // Xử lý Little Endian Byte 2
              }
              // Data decode lại bằng utf-8 từ arr bytes
              decodedHtml = utf8.decode(
                encoded.where((b) => b != 0).toList(),
                allowMalformed: true,
              );
            } catch (e) {
              debugPrint('[DROP] utf8 decode error: $e');
            }
          }
          debugPrint('[DROP] decoded html: $decodedHtml');

          // Thử tìm thẻ src="" hoặc http thẳng trong chuỗi đã decode (hoặc string gốc nếu lỗi)
          final imgRegex = RegExp(
            r'(?:src="|(?:https?:\/\/))([^"]+?(?:png|jpg|jpeg|gif|webp))',
            caseSensitive: false,
          );
          final match =
              imgRegex.firstMatch(decodedHtml) ?? imgRegex.firstMatch(html);

          var imgUrl = match?.group(1);
          if (imgUrl != null) {
            if (!imgUrl.startsWith('http')) {
              imgUrl = match?.group(0)?.startsWith('http') == true
                  ? match?.group(0)
                  : imgUrl;
            }
            if (imgUrl != null && imgUrl.startsWith('http')) {
              imgUrl = _resolve(imgUrl.replaceAll('&amp;', '&'));
              debugPrint('[DROP] extracted img: $imgUrl');
              widget.store.addCustomImage(
                imgUrl,
                0.5,
                0.5,
                isGif: imgUrl.toLowerCase().contains('.gif'),
              );
            }
          }
        }
      });
      return;
    }

    // 3. Fallback kéo ảnh gửi plain URI / text
    if (reader.canProvide(Formats.uri)) {
      reader.getValue<NamedUri>(Formats.uri, (NamedUri? uri) {
        debugPrint('[DROP] from uri: ${uri?.uri.toString()}');
        if (uri != null && uri.uri.scheme.startsWith('http')) {
          final url = _resolve(uri.uri.toString());
          widget.store.addCustomImage(
            url,
            0.5,
            0.5,
            isGif: url.toLowerCase().contains('.gif'),
          );
        }
      }, onError: (e) => debugPrint('[DROP] err: $e'));
      return;
    }

    if (reader.canProvide(Formats.plainText)) {
      reader.getValue<String>(Formats.plainText, (String? text) {
        debugPrint('[DROP] from text: $text');
        if (text != null && text.startsWith('http')) {
          final url = _resolve(text.trim());
          widget.store.addCustomImage(
            url,
            0.5,
            0.5,
            isGif: url.toLowerCase().contains('.gif'),
          );
        }
      });
      return;
    }
  }

  Future<void> _onPerformDrop(PerformDropEvent event) async {
    // Guard: widget vẫn alive trong PageView (KeepAlivePage) khi tab bị ẩn.
    // Nếu không ở Video Editor tab, bỏ qua hoàn toàn để tránh decode sai file.
    if (!widget.store.isOnVideoEditorTab) return;

    setState(() => _isDragging = false);
    debugPrint('[DROP] perform drop, items: ${event.session.items.length}');
    for (final item in event.session.items) {
      await _handleDropItem(item);
    }
  }



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _zoneFocus.requestFocus(),
      child: KeyboardListener(
        focusNode: _zoneFocus,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.keyV &&
              HardwareKeyboard.instance.isControlPressed) {
            _pasteFromClipboard();
          }
        },
        child: DropRegion(
          formats: const [
            Formats.fileUri, // file ảnh local (.png, .jpg, .gif …)
            Formats.htmlText, // kéo ảnh từ browser (có thẻ <img>)
            Formats.uri, // URL ảnh dạng URI
            Formats.plainText, // URL ảnh dạng text thuần
          ],
          onDropOver: (event) {
            // Guard: chặn khi không ở tab Video Editor
            if (!widget.store.isOnVideoEditorTab) return DropOperation.none;

            // Chỉ kích hoạt overlay khi kéo ảnh từ browser
            final hasWebImage = event.session.items.any(
              (item) =>
                  item.dataReader?.canProvide(Formats.htmlText) == true ||
                  item.dataReader?.canProvide(Formats.uri) == true,
            );
            if (hasWebImage && !_isDragging) {
              setState(() => _isDragging = true);
            } else if (!hasWebImage && _isDragging) {
              setState(() => _isDragging = false);
            }
            return DropOperation.copy;
          },
          onDropLeave: (event) {
            setState(() => _isDragging = false);
          },
          onPerformDrop: _onPerformDrop,
          child: Stack(
            children: [
              widget.child,
              if (_isDragging)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        border: Border.all(
                          color: const Color(0xFF6366F1),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              color: Color(0xFF6366F1),
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Thả ảnh vào đây',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
