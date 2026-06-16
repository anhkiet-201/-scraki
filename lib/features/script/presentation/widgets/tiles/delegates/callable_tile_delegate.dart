import 'package:flutter/material.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import '../script_tile_delegate.dart';
import 'default_tile_ui_mixin.dart';

/// Delegate cho kịch bản Callable (không thể chạy trực tiếp, chỉ dùng để gọi từ script khác).
class CallableTileDelegate with DefaultTileUiMixin implements ScriptTileDelegate {
  @override
  final ScriptTileDelegateCall? onRun = null; // Luôn luôn null vì kịch bản này không chạy trực tiếp
  
  @override
  final ScriptTileDelegateCall? onDelete;
  
  @override
  final ScriptTileDelegateCall? onEdit;
  
  @override
  final bool isExecuting;

  CallableTileDelegate({
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
          onPressed: () => onEdit?.call(script),
          icon: const Icon(Icons.edit_rounded, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          tooltip: 'Sửa script',
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _showDeleteConfirm(context, script),
          icon: const Icon(Icons.delete_outline_rounded, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.error.withValues(alpha: 0.6),
          tooltip: 'Xóa script',
        ),
      ],
    );
  }

  void _showDeleteConfirm(BuildContext context, ScriptEntity script) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Script'),
        content: Text('Bạn có chắc chắn muốn xóa script "${script.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call(script);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  void onTap(BuildContext context, ScriptEntity script) {
    onEdit?.call(script);
  }
}
