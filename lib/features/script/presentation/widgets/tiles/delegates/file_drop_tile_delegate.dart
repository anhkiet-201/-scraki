import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import '../script_tile_delegate.dart';

/// Delegate hỗ trợ kéo thả file/thư mục vào Tile (Sử dụng Decorator Pattern).
class FileDropTileDelegate implements ScriptTileDelegate {
  final ScriptTileDelegate child;
  final void Function(String path)? onFileDropped;

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
  final void Function(String path)? onFileDropped;

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
    final theme = Theme.of(context);

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
        for (final item in event.session.items) {
          final reader = item.dataReader;
          if (reader != null && reader.canProvide(Formats.fileUri)) {
            final completer = Completer<Uri?>();
            final dynamic dReader = reader;
            void callback(Object? value) {
              if (!completer.isCompleted) {
                completer.complete(value as Uri?);
              }
            }

            dReader.getValue(Formats.fileUri, callback);
            final uri = await completer.future;
            if (uri != null && uri.isScheme('file')) {
              final path = Uri.decodeComponent(uri.toFilePath());
              widget.onFileDropped?.call(path);
            }
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDraggingOver
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
          color: _isDraggingOver
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: widget.child,
      ),
    );
  }
}

