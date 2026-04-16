import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:scraki/features/video_poster/presentation/stores/video_poster_store.dart';

class ImageDropZone extends StatefulWidget {
  final VideoPosterStore store;
  final Widget child;

  const ImageDropZone({
    super.key,
    required this.store,
    required this.child,
  });

  @override
  State<ImageDropZone> createState() => _ImageDropZoneState();
}

class _ImageDropZoneState extends State<ImageDropZone> {
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
