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
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "TÀI NGUYÊN",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Theme.of(context).brightness == Brightness.light ? const Color(0xFF94A3B8) : Colors.white38,
            ),
          ),
        ),
        const SizedBox(height: 1),
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? const Color(0xFF6366F1).withValues(alpha: Theme.of(context).brightness == Brightness.light ? 0.08 : 0.15) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isActive && Theme.of(context).brightness == Brightness.light 
                                ? Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.1)) 
                                : null,
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.movie_outlined,
                              size: 16,
                              color: isActive ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                            ),
                            title: Text(
                              path.split('/').last,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive ? const Color(0xFF6366F1) : (Theme.of(context).brightness == Brightness.light ? const Color(0xFF475569) : Colors.white70),
                              ),
                            ),
                            onTap: () => onVideoTap(index),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.close_rounded, 
                                size: 14, 
                                color: Theme.of(context).brightness == Brightness.light ? const Color(0xFFCBD5E1) : Colors.white24,
                              ),
                              onPressed: () => store.removeSourceVideo(index),
                            ),
                          ),
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
