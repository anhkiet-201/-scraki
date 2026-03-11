import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

/// Media Library panel — drag-and-drop video file management
class MediaLibraryPanel extends StatelessWidget {
  final VideoPosterStore store;
  final ValueChanged<int> onVideoTap;

  const MediaLibraryPanel({
    super.key,
    required this.store,
    required this.onVideoTap,
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
          child: DropRegion(
            formats: Formats.standardFormats,
            onDropOver: (_) => DropOperation.copy,
            onPerformDrop: (event) async {
              // QUAN TRỌNG: onPerformDrop block platform thread (Windows message loop).
              // KHÔNG được await bất kỳ thứ gì ở đây — phải return ngay lập tức.
              // Dùng Completer để thu thập paths từ callbacks bất đồng bộ,
              // sau đó xử lý qua Future.microtask sau khi platform thread được giải phóng.
              final paths = <String>[];
              int pending = 0;

              void tryFinish() {
                pending--;
                if (pending == 0 && paths.isNotEmpty) {
                  // Chạy sau khi onPerformDrop return — không block platform thread
                  Future.microtask(() => store.addSourceVideos(paths));
                }
              }

              for (final item in event.session.items) {
                final reader = item.dataReader;
                if (reader != null && reader.canProvide(Formats.fileUri)) {
                  pending++;
                  reader.getValue<Uri>(Formats.fileUri, (Uri? uri) {
                    if (uri != null) paths.add(uri.toFilePath());
                    tryFinish();
                  });
                }
              }

              // Không có item nào hợp lệ — không cần làm gì
            },
            child: Observer(
              builder: (_) => ListView.builder(
                itemCount: store.sourceVideoPaths.length,
                itemBuilder: (context, index) {
                  return Observer(
                    builder: (context) {
                      final path = store.sourceVideoPaths[index];
                      final isActive =
                          index == store.currentVideoIndex && store.isPlaying;
                      return ListTile(
                        dense: true,
                        selected: isActive,
                        selectedTileColor: Colors.white.withValues(alpha: 0.1),
                        leading: Icon(
                          Icons.movie_outlined,
                          size: 16,
                          color: isActive ? Colors.greenAccent : Colors.white70,
                        ),
                        title: Text(
                          path.split('/').last,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isActive ? Colors.greenAccent : Colors.white,
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
