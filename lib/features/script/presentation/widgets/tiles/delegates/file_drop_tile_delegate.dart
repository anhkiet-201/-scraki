import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import '../script_tile_delegate.dart';

/// Delegate hỗ trợ kéo thả file/thư mục vào Tile (Sử dụng Decorator Pattern).
class FileDropTileDelegate implements ScriptTileDelegate {
  final ScriptTileDelegate child;
  final void Function(String paths)? onFileDropped;

  FileDropTileDelegate({
    required this.child,
    this.onFileDropped,
  });

  @override
  ScriptTileDelegateCall? get onRun => child.onRun;

  @override
  ScriptTileDelegateCall? get onDelete => child.onDelete;

  @override
  ScriptTileDelegateCall? get onEdit => child.onEdit;

  @override
  bool get isExecuting => child.isExecuting;

  @override
  Widget? buildLeading(BuildContext context, ScriptEntity script) => child.buildLeading(context, script);

  @override
  Widget buildTitle(BuildContext context, ScriptEntity script) => child.buildTitle(context, script);

  @override
  Widget? buildSubtitle(BuildContext context, ScriptEntity script) => child.buildSubtitle(context, script);

  @override
  Widget? buildTrailing(BuildContext context, ScriptEntity script) => child.buildTrailing(context, script);

  @override
  void onTap(BuildContext context, ScriptEntity script) => child.onTap(context, script);

  @override
  Widget wrap(BuildContext context, Widget tileChild, ScriptEntity script) {
    final wrappedChild = child.wrap(context, tileChild, script);
    return _DropHighlightWrapper(
      onFileDropped: onFileDropped,
      child: wrappedChild,
    );
  }
}

class _DropHighlightWrapper extends StatefulWidget {
  final Widget child;
  final void Function(String paths)? onFileDropped;

  const _DropHighlightWrapper({
    required this.child,
    this.onFileDropped,
  });

  @override
  State<_DropHighlightWrapper> createState() => _DropHighlightWrapperState();
}

class _DropHighlightWrapperState extends State<_DropHighlightWrapper> {
  bool _isDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    return DropRegion(
      formats: const [Formats.fileUri],
      onDropEnter: (event) {
        setState(() => _isDraggingOver = true);
      },
      onDropLeave: (event) {
        setState(() => _isDraggingOver = false);
      },
      onDropOver: (event) {
        final canAccept = event.session.items.any(
          (item) => item.dataReader?.canProvide(Formats.fileUri) == true,
        );
        return canAccept ? DropOperation.copy : DropOperation.none;
      },
      onPerformDrop: (event) async {
        setState(() => _isDraggingOver = false);
        final futures = event.session.items.map((item) async {
          final reader = item.dataReader;
          if (reader != null && reader.canProvide(Formats.fileUri)) {
            final completer = Completer<Uri?>();
            final dynamic dReader = reader;
            dReader.getValue(Formats.fileUri, (Object? value) {
              if (!completer.isCompleted) {
                completer.complete(value as Uri?);
              }
            });
            final uri = await completer.future;
            if (uri != null && uri.isScheme('file')) {
              return Uri.decodeComponent(uri.toFilePath());
            }
          }
          return null;
        });

        final results = await Future.wait(futures);
        final paths = results.whereType<String>().toList();

        if (paths.isNotEmpty) {
          widget.onFileDropped?.call(paths.join('\n'));
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDraggingOver)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isDraggingOver ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4F46E5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            color: Color(0xFF4F46E5),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Thả file để nạp đường dẫn {file}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
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
    );
  }
}

