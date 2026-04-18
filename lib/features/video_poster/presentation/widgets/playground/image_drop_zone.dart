import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';
import 'package:scraki/features/video_poster/presentation/stores/image_drop_store.dart';

class ImageDropZone extends StatelessWidget {
  final VideoPosterStore store;
  final Widget child;

  const ImageDropZone({
    super.key,
    required this.store,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dropStore = getIt<ImageDropStore>();

    return Observer(
      builder: (context) {
        return DropRegion(
          formats: const [
            Formats.fileUri,
            Formats.htmlText,
            Formats.uri,
            Formats.plainText,
            Formats.png,
            Formats.jpeg,
            Formats.webp,
            Formats.gif,
          ],
          onDropOver: (event) => dropStore.handleDropOver(event, store.isOnVideoEditorTab),
          onDropLeave: (event) => dropStore.setDragging(false),
          onPerformDrop: (event) async {
            dropStore.handlePerformDrop(
              event,
              onImageFound: (path, isGif) {
                store.addCustomImage(path, 0.5, 0.5, isGif: isGif);
              },
            );
          },
          child: Stack(
            children: [
              child,
              if (dropStore.isDragging)
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
              if (dropStore.isProcessing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
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
