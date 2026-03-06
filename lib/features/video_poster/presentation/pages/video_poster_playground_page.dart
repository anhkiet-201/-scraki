import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'package:scraki/features/video_poster/presentation/widgets/preview/video_overlay_item/video_overlay_item.dart';
import 'package:scraki/features/video_poster/presentation/widgets/controls/floating_glass_controls.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/media_library_panel.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/text_properties_panel.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/batch_video_panel.dart';

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
                                  builder: (_) =>
                                      store.activeNavIndex == _kNavText
                                      ? TextPropertiesPanel(store: store)
                                      : MediaLibraryPanel(
                                          store: store,
                                          onVideoTap: store.playVideoAtIndex,
                                        ),
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
                                            onPlayPause: () =>
                                                store.player.playOrPause(),
                                            onSeek: (d) => store.player.seek(d),
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
              if (store.isBatchCreating) return const SizedBox.shrink();
              return _buildActionButton('DỰ ÁN MỚI', Icons.add_rounded, () {
                store.resetProject();
              });
            },
          ),
          const SizedBox(width: 12),
        ],
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
                                        fontFamily: text.fontFamily,
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
