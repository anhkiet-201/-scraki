import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

import 'package:scraki/features/video_poster/presentation/widgets/preview/tiktok_safe_zone.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/video_overlay_item/video_overlay_item.dart';
import 'package:scraki/features/video_poster/presentation/widgets/controls/floating_glass_controls.dart';
import 'package:scraki/features/video_poster/presentation/widgets/controls/duration_status_overlay.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/media_library_panel.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/text_properties_panel.dart';

/// Nav tab index constants
const int _kNavMedia = 0;
const int _kNavText = 1;

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
              store.player.seek(Duration.zero);
              store.player.play();
            } else {
              store.player.playOrPause();
            }
          },
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
            store.toggleFocusMode();
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Column(
              children: [
                _buildModernToolbar(),
                Expanded(
                  child: Row(
                    children: [
                      // Left nav bar
                      _buildUnifiedNavBar(),

                      // Left panel (media library or text properties)
                      Observer(
                        builder: (_) {
                          if (store.isFocusMode) return const SizedBox.shrink();
                          return SizedBox(
                            width: 300,
                            child: store.activeNavIndex == _kNavText
                                ? TextPropertiesPanel(store: store)
                                : MediaLibraryPanel(
                                    store: store,
                                    onVideoTap: store.playVideoAtIndex,
                                    onVideosChanged: store.syncPlaylist,
                                  ),
                          );
                        },
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
                                    position: store.totalPosition,
                                    duration: store.totalDuration,
                                    onPlayPause: () =>
                                        store.player.playOrPause(),
                                    onSeek: store.seekTimeline,
                                  ),
                                ),
                              ),

                              // Status overlay
                              Positioned(
                                top: 20,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: DurationStatusOverlay(
                                    duration: store.duration,
                                    playbackSpeed: store.playbackSpeed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
          _buildWorkStepper(),
          const Spacer(),
          _buildActionButton('DỰ ÁN MỚI', Icons.add_rounded, () {
            store.sourceVideoPaths.clear();
            store.customTexts.clear();
            store.player.open(Playlist([]));
          }),
          const SizedBox(width: 12),
          _buildActionButton(
            'CÀI ĐẶT',
            Icons.settings_outlined,
            () {},
            isOutline: true,
          ),
          const SizedBox(width: 12),
          Observer(
            builder: (_) => _buildActionButton(
              store.isFocusMode ? 'THOÁT TẬP TRUNG' : 'CHẾ ĐỘ TẬP TRUNG',
              store.isFocusMode
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
              store.toggleFocusMode,
              isOutline: store.isFocusMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkStepper() {
    return Observer(
      builder: (_) {
        int step = 1;
        if (store.sourceVideoPaths.isNotEmpty) step = 2;
        if (store.isProcessing) step = 3;
        if (store.generatedVideoPath != null) step = 4;

        return Row(
          children: [
            _buildStepperItem(1, 'MEDIA', step >= 1),
            _buildStepperDivider(step >= 2),
            _buildStepperItem(2, 'TEXT', step >= 2),
            _buildStepperDivider(step >= 3),
            _buildStepperItem(3, 'EDIT', step >= 3),
            _buildStepperDivider(step >= 4),
            _buildStepperItem(4, 'READY', step >= 4),
          ],
        );
      },
    );
  }

  Widget _buildStepperItem(int num, String label, bool active) {
    final color = active ? const Color(0xFF6366F1) : Colors.white24;
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
            color: active ? color.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Center(
            child: Text(
              num.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: active ? Colors.white70 : Colors.white24,
          ),
        ),
      ],
    );
  }

  Widget _buildStepperDivider(bool active) {
    return Container(
      width: 24,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: active
          ? const Color(0xFF6366F1).withValues(alpha: 0.5)
          : Colors.white10,
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
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
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

                  // TikTok Safe Zone Visualization
                  const TikTokSafeZone(),

                  // Virtual canvas for free text overlays (720x1280)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.contain,
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
                                onTap: () => store.selectCustomText(null),
                                behavior: HitTestBehavior.opaque,
                                child: Stack(
                                  children: [
                                    // Transparent background — shows video below
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.transparent,
                                      ),
                                    ),

                                    // Free-form custom text overlays
                                    ...store.customTexts.map(
                                      (text) => VideoOverlayItem(
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
                                        backgroundOpacity:
                                            text.backgroundOpacity,
                                        backgroundRadius: text.backgroundRadius,
                                        isSelected:
                                            store.selectedCustomTextId ==
                                            text.id,
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
                                      ),
                                    ),
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
    );
  }
}
