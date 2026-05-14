import 'package:flutter/material.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';

typedef ScriptTileDelegateCall = void Function(ScriptEntity script, [Map<String, String>? args]);

abstract interface class ScriptTileDelegate {
  ScriptTileDelegateCall? get onRun;
  ScriptTileDelegateCall? get onDelete;
  ScriptTileDelegateCall? get onEdit;
  bool get isExecuting;

  Widget? buildLeading(BuildContext context, ScriptEntity script);
  Widget buildTitle(BuildContext context, ScriptEntity script);
  Widget? buildSubtitle(BuildContext context, ScriptEntity script);
  Widget? buildTrailing(BuildContext context, ScriptEntity script);
  void onTap(BuildContext context, ScriptEntity script);

  /// Cho phép delegate bọc (wrap) Widget Tile bằng một Widget khác (ví dụ: DropRegion).
  Widget wrap(BuildContext context, Widget child, ScriptEntity script);
}
