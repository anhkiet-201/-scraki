import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'package:scraki/features/video_poster/presentation/widgets/controls/floating_glass_controls.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/media_library_panel.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/text_properties_panel.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/batch_video_panel.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/image_library_panel.dart';
import 'package:scraki/features/video_poster/presentation/widgets/panels/image_poster_panel.dart';

// Playground Components
import 'package:scraki/features/video_poster/presentation/widgets/playground/playground_toolbar.dart';
import 'package:scraki/features/video_poster/presentation/widgets/playground/playground_nav_bar.dart';
import 'package:scraki/features/video_poster/presentation/widgets/playground/playground_interactive_preview.dart';
import 'package:scraki/features/video_poster/presentation/widgets/playground/playground_slide_strip.dart';
import 'package:scraki/features/video_poster/presentation/widgets/playground/playground_constants.dart';

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
            if (store.isImagePosterMode) return;
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
                PlaygroundToolbar(store: store),
                Expanded(
                  child: Observer(
                    builder: (context) {
                      return Stack(
                        children: [
                          Row(
                            children: [
                              PlaygroundNavBar(store: store),
                              _buildLeftPanel(),
                              _buildMainContent(),
                              _buildRightPanel(),
                            ],
                          ),
                          _buildOverlayPanel(context),
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

  Widget _buildLeftPanel() {
    return SizedBox(
      width: PlaygroundConstants.kPropertiesPanelWidth,
      child: Observer(
        builder: (_) {
          if (store.activeNavIndex == PlaygroundConstants.kNavText) {
            return TextPropertiesPanel(store: store);
          } else if (store.activeNavIndex == PlaygroundConstants.kNavImage) {
            return ImageLibraryPanel(store: store);
          } else {
            return MediaLibraryPanel(
              store: store,
              onVideoTap: store.playVideoAtIndex,
            );
          }
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return Expanded(
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
                  child: PlaygroundInteractivePreview(store: store),
                ),
              ),
              if (store.isImagePosterMode)
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  height: 100,
                  child: PlaygroundSlideStrip(
                    store: store,
                    scrollController: _slideScrollController,
                  ),
                ),
              if (!store.isImagePosterMode)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingGlassControls(
                      isPlaying: store.isPlaying,
                      isMuted: store.isMuted,
                      position: store.position,
                      duration: store.duration,
                      onPlayPause: () {
                        if (store.isPlaying) {
                          store.player.pause();
                        } else {
                          store.player.play();
                        }
                      },
                      onToggleMute: store.toggleMute,
                      onSeek: (p) => store.seekProject(p),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return SizedBox(
      width: PlaygroundConstants.kBatchPanelWidth,
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
    );
  }

  Widget _buildOverlayPanel(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      top: 0,
      bottom: 0,
      left: store.isBatchCreating ? 0 : MediaQuery.of(context).size.width,
      right: store.isBatchCreating ? 0 : -MediaQuery.of(context).size.width,
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
    );
  }
}
