import 'package:flutter/material.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import '../script_tile_delegate.dart';

mixin DefaultTileUiMixin implements ScriptTileDelegate {
  @override
  Widget? buildLeading(BuildContext context, ScriptEntity script) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.terminal_rounded,
        size: 16,
        color: theme.colorScheme.primary,
      ),
    );
  }

  @override
  Widget buildTitle(BuildContext context, ScriptEntity script) {
    final theme = Theme.of(context);
    return Text(
      script.name,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1E293B), // Slate 800
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget? buildSubtitle(BuildContext context, ScriptEntity script) {
    if (script.description.isEmpty) return null;
    final theme = Theme.of(context);
    return Text(
      script.description,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        color: const Color(0xFF64748B), // Slate 500
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget wrap(BuildContext context, Widget child, ScriptEntity script) => child;
}
