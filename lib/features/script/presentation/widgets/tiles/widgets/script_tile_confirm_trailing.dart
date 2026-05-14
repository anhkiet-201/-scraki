import 'package:flutter/material.dart';

class ScriptTileConfirmTrailing extends StatefulWidget {
  final VoidCallback? onRun;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isExecuting;

  const ScriptTileConfirmTrailing({
    super.key,
    this.onRun,
    this.onDelete,
    this.onEdit,
    this.isExecuting = false,
  });

  @override
  State<ScriptTileConfirmTrailing> createState() => _ScriptTileConfirmTrailingState();
}

class _ScriptTileConfirmTrailingState extends State<ScriptTileConfirmTrailing> {
  bool _confirmingRun = false;
  bool _confirmingDelete = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_confirmingRun) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              setState(() => _confirmingRun = false);
              widget.onRun?.call();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
            child: const Text('Chạy ?'),
          ),
          IconButton(
            onPressed: () => setState(() => _confirmingRun = false),
            icon: const Icon(Icons.close_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: Colors.grey,
          ),
        ],
      );
    }

    if (_confirmingDelete) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              setState(() => _confirmingDelete = false);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Xóa ?'),
          ),
          IconButton(
            onPressed: () => setState(() => _confirmingDelete = false),
            icon: const Icon(Icons.close_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: Colors.grey,
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            if (widget.isExecuting) {
              widget.onRun?.call();
            } else {
              setState(() => _confirmingRun = true);
            }
          },
          icon: Icon(
            widget.isExecuting
                ? Icons.stop_circle_rounded
                : Icons.play_arrow_rounded,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: widget.isExecuting
              ? Colors.redAccent
              : const Color(0xFF10B981),
          tooltip: widget.isExecuting ? 'Dừng script' : 'Chạy script',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: widget.onEdit,
          icon: const Icon(Icons.edit_rounded, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          tooltip: 'Sửa script',
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => setState(() => _confirmingDelete = true),
          icon: const Icon(Icons.delete_outline_rounded, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.error.withValues(alpha: 0.6),
          tooltip: 'Xóa script',
        ),
      ],
    );
  }
}
