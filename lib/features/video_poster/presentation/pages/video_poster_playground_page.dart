import 'dart:async';
import 'dart:io';
import 'dart:ui' show lerpDouble;
import 'package:flutter/gestures.dart';
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
import 'package:scraki/features/video_poster/presentation/widgets/panels/image_poster_panel.dart';

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
  late final ScrollController _slideScrollController;

  @override
  void initState() {
    super.initState();
    store = GetIt.I<VideoPosterStore>();
    _slideScrollController = ScrollController();
  }

  @override
  void dispose() {
    _slideScrollController.dispose();
    store.disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        cardColor: const Color(0xFFF8FAFC),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6366F1),
          surface: Colors.white,
          onSurface: Color(0xFF0F172A),
        ),
        dividerColor: Colors.transparent,
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
                          Row(
                            children: [
                              _buildUnifiedNavBar(),
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
                              Expanded(
                                child: Observer(
                                  builder: (context) => Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          right: 0,
                                          bottom: store.isImagePosterMode ? 160 : 0,
                                          child: Center(
                                            child: _buildInteractivePreview(),
                                          ),
                                        ),
                                        if (store.isImagePosterMode)
                                          Positioned(
                                            bottom: 40,
                                            left: 20,
                                            right: 20,
                                            height: 100,
                                            child: _buildSlideStrip(),
                                          ),
                                        if (!store.isImagePosterMode)
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
                              ),
                              SizedBox(
                                width: 280,
                                child: Observer(
                                  builder: (_) {
                                    if (store.isImagePosterMode) {
                                      return ImagePosterPanel(store: store);
                                    }
                                    return BatchVideoPanel(
                                      key: const ValueKey('panel_base'),
                                      store: store,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            top: 0,
                            bottom: 0,
                            left: store.isBatchCreating
                                ? 0
                                : MediaQuery.of(context).size.width,
                            right: store.isBatchCreating
                                ? 0
                                : -MediaQuery.of(context).size.width,
                            child: Material(
                              elevation: 16,
                              child: Observer(
                                builder: (_) {
                                  if (store.isImagePosterMode) {
                                    return ImagePosterPanel(store: store);
                                  }
                                  return BatchVideoPanel(
                                    key: const ValueKey('panel_overlay'),
                                    store: store,
                                  );
                                },
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

  Widget _buildModernToolbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: null,
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
              color: Color(0xFF475569),
            ),
          ),
          const Spacer(),
          Observer(
            builder: (_) {
              return Row(
                children: [
                  _buildOutputToggle(),
                  const SizedBox(width: 12),
                   if (!store.isImagePosterMode) ...[
                     const SizedBox(width: 12),
                     _buildModeToggle(),
                   ],
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

  Widget _buildOutputToggle() {
    return Observer(
      builder: (_) {
        final isImageMode = store.isImagePosterMode;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeOption(
                label: 'VIDEO',
                icon: Icons.movie_outlined,
                isActive: !isImageMode,
                onTap: () {
                  if (isImageMode) store.toggleImagePosterMode();
                },
              ),
              _buildModeOption(
                label: 'POSTER',
                icon: Icons.image_outlined,
                isActive: isImageMode,
                onTap: () {
                  if (!isImageMode) store.toggleImagePosterMode();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeToggle() {
    return Observer(
      builder: (_) {
        final isPreview = store.isPreviewMode;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
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
          color: isOutline ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
          border: isOutline ? Border.all(color: Colors.black.withValues(alpha: 0.1)) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF475569)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedNavBar() {
    return Container(
      width: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
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
                    color: active ? Colors.white : const Color(0xFF94A3B8),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: active ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
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

  Widget _buildInteractivePreview() {
    return _ImageDropZone(
      store: store,
      child: Container(
        color: const Color(0xFFF1F5F9),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: AspectRatio(
            aspectRatio: store.isImagePosterMode ? 4 / 5 : 9 / 16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    Observer(
                      builder: (context) {
                        if (store.sourceVideoPaths.isEmpty) {
                          return Container(
                            color: Colors.white,
                            child: const Center(
                              child: Text(
                                'No Video Selected',
                                style: TextStyle(color: Color(0xFF94A3B8)),
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
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        clipBehavior: Clip.none,
                        child: SizedBox(
                          width: 720,
                          height: store.isImagePosterMode ? 900 : 1280,
                          child: RepaintBoundary(
                            key: store.previewKey,
                            child: Observer(
                              builder: (context) {
                                final virtualConstraints = BoxConstraints(
                                  maxWidth: 720,
                                  maxHeight: store.isImagePosterMode ? 900 : 1280,
                                );

                                return GestureDetector(
                                  onTap: () {
                                    store.selectCustomText(null);
                                    store.selectCustomImage(null);
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
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
                                              final adjustedX =
                                                  (localOffset.dx + 50) /
                                                  renderBox.size.width;
                                              final adjustedY =
                                                  (localOffset.dy + 50) /
                                                  renderBox.size.height;

                                              store.addCustomImage(
                                                details.data['url'] as String,
                                                adjustedX.clamp(0.0, 1.0),
                                                adjustedY.clamp(0.0, 1.0),
                                                isGif: details.data['isGif'] as bool,
                                              );
                                            }
                                          },
                                          builder: (context, candidateData, rejectedData) => Container(
                                            color: candidateData.isNotEmpty
                                                ? Colors.white.withValues(alpha: 0.1)
                                                : Colors.transparent,
                                          ),
                                        ),
                                      ),
                                      if (!store.isHidingImagesForCapture)
                                        ...store.customImages.where((image) {
                                          if (!store.isPreviewMode) return true;
                                          final pos = store.position.inMilliseconds / 1000.0;
                                          return pos >= image.startTime && (image.endTime == null || pos <= image.endTime!);
                                        }).map((image) => ImageOverlayItem(
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
                                          isSelected: store.selectedCustomImageId == image.id,
                                          onPositionUpdate: store.updateCustomImagePosition,
                                          onSelect: store.selectCustomImage,
                                          onResize: store.updateCustomImageSize,
                                          borderColor: image.borderColor,
                                          borderWidth: image.borderWidth,
                                          borderRadius: image.borderRadius,
                                        )),
                                      ...store.customTexts.where((text) {
                                        if (!store.isPreviewMode) return true;
                                        final pos = store.position.inMilliseconds / 1000.0;
                                        return pos >= text.startTime && (text.endTime == null || pos <= text.endTime!);
                                      }).map((text) => Observer(
                                        key: ValueKey('text_wrapper_${text.id}'),
                                        builder: (context) {
                                          final shouldHide = store.isHidingAnimatedTextsForCapture && text.isAnimated;
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
                                            captureKey: text.isAnimated ? store.getTextCaptureKey(text.id) : null,
                                            onPositionUpdate: (_, x, y) => store.updateCustomTextPosition(text.id, x, y),
                                            onSelect: (_) => store.selectCustomText(text.id),
                                            onResize: (_, size) => store.updateCustomTextFontSize(text.id, size),
                                            onTextChange: (_, val) => store.updateCustomTextLabel(text.id, val),
                                            animationInType: text.animationInType,
                                            animationInDuration: text.animationInDuration,
                                            animationOutType: text.animationOutType,
                                            animationOutDuration: text.animationOutDuration,
                                            isPreviewMode: store.isPreviewMode,
                                            currentTime: store.position.inMilliseconds / 1000.0,
                                            startTime: text.startTime,
                                            endTime: text.endTime ?? (store.duration.inMilliseconds.toDouble()) / 1000.0,
                                            triggerPreviewCounter: store.animationPreviewCounters[text.id] ?? 0,
                                            triggerOutPreviewCounter: store.animationOutPreviewCounters[text.id] ?? 0,
                                          );
                                        },
                                      )),
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

  Widget _buildSlideStrip() {
    return Observer(
      builder: (context) {
        if (!store.isImagePosterMode || store.slides.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Listener(
                    onPointerSignal: (pointerSignal) {
                      if (pointerSignal is PointerScrollEvent &&
                          _slideScrollController.hasClients) {
                        final newOffset = _slideScrollController.offset +
                            pointerSignal.scrollDelta.dy;
                        if (newOffset >= 0 &&
                            newOffset <=
                                _slideScrollController
                                    .position.maxScrollExtent) {
                          _slideScrollController.jumpTo(newOffset);
                        }
                      }
                    },
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    scrollController: _slideScrollController,
                    buildDefaultDragHandles: false,
                    itemCount: store.slides.length,
                    onReorder: store.reorderSlides,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final double animValue =
                              Curves.easeInOut.transform(animation.value);
                          final double scale = lerpDouble(1, 1.05, animValue)!;
                          return Transform.scale(
                            scale: scale,
                            child: Material(
                              color: Colors.transparent,
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final slide = store.slides[index];
                      final isActive = store.currentSlideIndex == index;

                      return ReorderableDragStartListener(
                        key: ValueKey(slide.id),
                        index: index,
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => store.selectSlide(index),
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFF6366F1)
                                      : Colors.black.withValues(alpha: 0.05),
                                  width: isActive ? 2 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.copy_all_rounded,
                                          size: 20,
                                          color: isActive
                                              ? const Color(0xFF6366F1)
                                              : Colors.grey,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          slide.name,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isActive
                                                ? const Color(0xFF6366F1)
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (store.slides.length > 1)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () => store.removeSlide(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 10,
                                            color: Colors.white,
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
                ),
              ),
              const SizedBox(width: 12),
              // Shuffle Content Button
              Tooltip(
                message: 'Ngẫu nhiên nội dung',
                child: GestureDetector(
                  onTap: store.randomizePreviewFrame,
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      ),
                    ),
                    child: const Icon(
                      Icons.shuffle_rounded,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: store.addSlide,
                child: Container(
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Drop Zone ─────────────────────────────────────────────────────────────

class _ImageDropZone extends StatefulWidget {
  final VideoPosterStore store;
  final Widget child;
  const _ImageDropZone({required this.store, required this.child});

  @override
  State<_ImageDropZone> createState() => _ImageDropZoneState();
}

class _ImageDropZoneState extends State<_ImageDropZone> {
  bool _isDragging = false;
  final _zoneFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _zoneFocus.requestFocus(),
    );
  }

  @override
  void dispose() {
    _zoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _zoneFocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyV &&
            HardwareKeyboard.instance.isControlPressed) {
          _pasteFromClipboard();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: DropRegion(
        formats: const [
          Formats.fileUri,
          Formats.htmlText,
          Formats.uri,
          Formats.plainText,
        ],
        onDropOver: (event) {
          if (!widget.store.isOnVideoEditorTab) return DropOperation.none;
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
    );
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) return;
      if (text.startsWith('http')) {
        widget.store.addCustomImage(
          text,
          0.5,
          0.5,
          isGif: text.toLowerCase().endsWith('.gif'),
        );
      }
    } catch (e) {
      debugPrint('[PASTE] error: $e');
    }
  }

  Future<void> _onPerformDrop(PerformDropEvent event) async {
    setState(() => _isDragging = false);
    for (final item in event.session.items) {
      final reader = item.dataReader;
      if (reader == null) continue;

      if (reader.canProvide(Formats.fileUri)) {
        reader.getValue(Formats.fileUri, (uri) {
          if (uri != null) {
            final path = Uri.decodeComponent(uri.toFilePath());
            if (path.toLowerCase().endsWith('.png') ||
                path.toLowerCase().endsWith('.jpg') ||
                path.toLowerCase().endsWith('.jpeg') ||
                path.toLowerCase().endsWith('.gif') ||
                path.toLowerCase().endsWith('.webp')) {
              widget.store.addCustomImage(path, 0.5, 0.5, isGif: path.toLowerCase().endsWith('.gif'));
            }
          }
        });
      } else if (reader.canProvide(Formats.htmlText)) {
        reader.getValue(Formats.htmlText, (html) {
          if (html != null) {
            final match = RegExp(r'src="([^"]+)"').firstMatch(html);
            if (match != null) {
              final url = match.group(1)!;
              widget.store.addCustomImage(url, 0.5, 0.5, isGif: url.toLowerCase().contains('.gif'));
            }
          }
        });
      }
    }
  }
}
