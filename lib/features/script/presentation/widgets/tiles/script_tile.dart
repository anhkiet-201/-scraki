import 'package:flutter/material.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/script/presentation/widgets/tiles/script_tile_delegate.dart';

/// Widget đại diện cho một Script Tile trong danh sách.
/// Giao diện và hành vi được ủy quyền (delegate) cho [ScriptTileDelegate].
class ScriptTile extends StatelessWidget {
  final ScriptEntity script;
  final ScriptTileDelegate delegate;

  const ScriptTile({
    super.key,
    required this.script,
    required this.delegate,
  });

  @override
  Widget build(BuildContext context) {
    final leading = delegate.buildLeading(context, script);
    final title = delegate.buildTitle(context, script);
    final subtitle = delegate.buildSubtitle(context, script);
    final trailing = delegate.buildTrailing(context, script);

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)), // Slate 100
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => delegate.onTap(context, script),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        subtitle,
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // Bọc Tile bằng widget đặc biệt nếu delegate yêu cầu (ví dụ: DropRegion)
    return delegate.wrap(context, tile, script);
  }
}
