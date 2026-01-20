import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

/// Media Library panel for video file management
///
/// Features:
/// - Drag and drop video files
/// - Video list display
/// - Remove video functionality
/// - Video selection callback
class MediaLibraryPanel extends StatelessWidget {
  final VideoPosterStore store;
  final ValueChanged<int> onVideoTap;
  final VoidCallback onVideosChanged;

  const MediaLibraryPanel({
    super.key,
    required this.store,
    required this.onVideoTap,
    required this.onVideosChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "TÀI NGUYÊN",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: DropTarget(
            onDragDone: (details) {
              final paths = details.files.map((e) => e.path).toList();
              store.addSourceVideos(paths);
              onVideosChanged();
            },
            child: Observer(
              builder: (_) => ListView.builder(
                itemCount: store.sourceVideoPaths.length,
                itemBuilder: (context, index) {
                  return Observer(
                    builder: (context) {
                      final path = store.sourceVideoPaths[index];
                      final isPlaying = index == store.currentPlaylistIndex;
                      return ListTile(
                        dense: true,
                        selected: isPlaying,
                        selectedTileColor: Colors.white.withValues(alpha: 0.1),
                        leading: Icon(
                          Icons.movie_outlined,
                          size: 16,
                          color: isPlaying
                              ? Colors.greenAccent
                              : Colors.white70,
                        ),
                        title: Text(
                          path.split('/').last,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isPlaying
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isPlaying
                                ? Colors.greenAccent
                                : Colors.white,
                          ),
                        ),
                        onTap: () => onVideoTap(index),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 14),
                          onPressed: () => store.removeSourceVideo(index),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
