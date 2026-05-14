import 'package:flutter/material.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import '../script_tile_delegate.dart';
import 'default_tile_ui_mixin.dart';

/// Delegate hỗ trợ xác nhận hành động thông qua Dialog.
class DialogTileDelegate with DefaultTileUiMixin implements ScriptTileDelegate {
  @override
  final ScriptTileDelegateCall? onRun;

  @override
  final ScriptTileDelegateCall? onDelete;

  @override
  final ScriptTileDelegateCall? onEdit;

  @override
  final bool isExecuting;

  DialogTileDelegate({
    this.onRun,
    this.onDelete,
    this.onEdit,
    this.isExecuting = false,
  });

  @override
  Widget? buildTrailing(BuildContext context, ScriptEntity script) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            if (isExecuting) {
              onRun?.call(script);
            } else {
              _showConfirmDialog(
                context,
                title: 'Chạy Script',
                content: 'Bạn có muốn chạy script "${script.name}" không?',
                onConfirm: () => onRun?.call(script),
              );
            }
          },
          icon: Icon(
            isExecuting ? Icons.stop_circle_rounded : Icons.play_arrow_rounded,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: isExecuting ? Colors.redAccent : const Color(0xFF10B981),
          tooltip: isExecuting ? 'Dừng script' : 'Chạy script',
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => onEdit?.call(script),
          icon: const Icon(Icons.edit_rounded, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          tooltip: 'Sửa script',
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _showConfirmDialog(
            context,
            title: 'Xóa Script',
            content: 'Bạn có chắc chắn muốn xóa script "${script.name}" không?',
            isDestructive: true,
            onConfirm: () => onDelete?.call(script),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.error.withValues(alpha: 0.6),
          tooltip: 'Xóa script',
        ),
      ],
    );
  }

  @override
  void onTap(BuildContext context, ScriptEntity script) {
    onEdit?.call(script);
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.redAccent)
                : null,
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
