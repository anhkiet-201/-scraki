import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:scraki/features/video_poster/data/services/image_drop_service.dart';

part 'image_drop_store.g.dart';

@injectable
class ImageDropStore = _ImageDropStoreBase with _$ImageDropStore;

abstract class _ImageDropStoreBase with Store {
  final ImageDropService _imageDropService;

  _ImageDropStoreBase(this._imageDropService);

  @observable
  bool isDragging = false;

  @observable
  bool isProcessing = false;

  @action
  void setDragging(bool value) {
    isDragging = value;
  }

  /// Xử lý thả ảnh (Non-blocking).
  /// Giải phóng Platform Thread ngay lập tức và xử lý logic trong Background.
  @action
  void handlePerformDrop(PerformDropEvent event, {required void Function(String path, bool isGif) onImageFound}) {
    setDragging(false);
    
    // Sử dụng Future.microtask để giải phóng onPerformDrop ngay lập tức
    Future.microtask(() async {
      isProcessing = true;
      try {
        for (final item in event.session.items) {
          final result = await _imageDropService.handleDropItem(item);
          if (result != null) {
            final isGif = result.toLowerCase().contains('.gif');
            onImageFound(result, isGif);
          }
        }
      } catch (e) {
        debugPrint('[ImageDropStore] Error processing dropped items: $e');
      } finally {
        isProcessing = false;
      }
    });
  }

  @action
  DropOperation handleDropOver(DropOverEvent event, bool isOnVideoEditorTab) {
    if (!isOnVideoEditorTab) return DropOperation.none;
    
    final canAccept = event.session.items.any(
      (item) =>
          item.dataReader?.canProvide(Formats.fileUri) == true ||
          item.dataReader?.canProvide(Formats.htmlText) == true ||
          item.dataReader?.canProvide(Formats.uri) == true ||
          item.dataReader?.canProvide(Formats.plainText) == true ||
          item.dataReader?.canProvide(Formats.png) == true ||
          item.dataReader?.canProvide(Formats.jpeg) == true ||
          item.dataReader?.canProvide(Formats.webp) == true ||
          item.dataReader?.canProvide(Formats.gif) == true,
    );

    if (canAccept && !isDragging) {
      setDragging(true);
    }
    return canAccept ? DropOperation.copy : DropOperation.none;
  }
}
