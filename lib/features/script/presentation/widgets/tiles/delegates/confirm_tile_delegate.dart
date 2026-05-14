import 'package:flutter/material.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import '../script_tile_delegate.dart';
import 'default_tile_ui_mixin.dart';
import '../widgets/script_tile_confirm_trailing.dart';

/// Delegate hỗ trợ xác nhận inline khi Chạy hoặc Xóa.
class ConfirmTileDelegate with DefaultTileUiMixin implements ScriptTileDelegate {
  @override
  final ScriptTileDelegateCall? onRun;
  
  @override
  final ScriptTileDelegateCall? onDelete;
  
  @override
  final ScriptTileDelegateCall? onEdit;
  
  @override
  final bool isExecuting;

  ConfirmTileDelegate({
    this.onRun,
    this.onDelete,
    this.onEdit,
    this.isExecuting = false,
  });

  @override
  Widget? buildTrailing(BuildContext context, ScriptEntity script) {
    return ScriptTileConfirmTrailing(
      onRun: () => onRun?.call(script),
      onDelete: () => onDelete?.call(script),
      onEdit: () => onEdit?.call(script),
      isExecuting: isExecuting,
    );
  }

  @override
  void onTap(BuildContext context, ScriptEntity script) {
    onEdit?.call(script);
  }
}
