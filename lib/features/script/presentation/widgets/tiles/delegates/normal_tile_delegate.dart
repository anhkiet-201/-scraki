import 'package:flutter/material.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import '../script_tile_delegate.dart';
import 'default_tile_ui_mixin.dart';

/// Delegate mặc định, hiển thị thông tin và các nút thao tác cơ bản.
class NormalTileDelegate with DefaultTileUiMixin implements ScriptTileDelegate {
  @override
  final ScriptTileDelegateCall? onRun;
  
  @override
  final ScriptTileDelegateCall? onDelete;
  
  @override
  final ScriptTileDelegateCall? onEdit;
  
  @override
  final bool isExecuting;

  NormalTileDelegate({
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
          onPressed: () => onRun?.call(script),
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: const Color(0xFF10B981), // Emerald
          tooltip: 'Chạy script',
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
          onPressed: () => onDelete?.call(script),
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
}
