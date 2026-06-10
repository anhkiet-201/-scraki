import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/script/presentation/stores/script_management_store.dart';
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
    return Observer(
      builder: (context) {
        final store = getIt<ScriptManagementStore>();
        final staged = store.stagedFiles[script.id];
        
        final hasDesc = script.description.isNotEmpty;
        final hasStaged = staged != null && staged.trim().isNotEmpty;
        
        if (!hasDesc && !hasStaged) return const SizedBox.shrink();
        
        String? stagedText;
        if (hasStaged) {
          final files = staged.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          if (files.isNotEmpty) {
            if (files.length == 1) {
              final fileName = files.first.split(RegExp(r'[/\\]')).last;
              stagedText = '📁 $fileName';
            } else {
              stagedText = '📁 ${files.length} files';
            }
          }
        }
        
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasDesc)
              Text(
                script.description,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: const Color(0xFF64748B), // Slate 500
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (stagedText != null) ...[
              if (hasDesc) const SizedBox(height: 2),
              Text(
                stagedText,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: const Color(0xFF10B981), // Emerald 500
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget wrap(BuildContext context, Widget child, ScriptEntity script) {
    if (isExecuting) {
      return Opacity(
        opacity: 0.6,
        child: AbsorbPointer(child: child),
      );
    }
    return child;
  }
}
