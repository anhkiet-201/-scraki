import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/script/presentation/stores/script_management_store.dart';
import 'package:scraki/features/script/presentation/stores/terminal_store.dart';

class ScriptSidebar extends StatelessWidget {
  final ScriptManagementStore scriptStore;
  final TerminalStore terminalStore;

  const ScriptSidebar({
    super.key,
    required this.scriptStore,
    required this.terminalStore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SCRIPTS',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFF64748B), // Slate 500
                ),
              ),
              IconButton(
                onPressed: () => scriptStore.updateEditingScript(
                  name: 'Script mới',
                  description: '',
                  commands: [],
                ),
                icon: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Tạo script mới',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Observer(
              builder: (_) {
                if (scriptStore.scripts.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có script nào.\nNhấn + để tạo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: scriptStore.scripts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return Observer(
                      builder: (context) {
                        final script = scriptStore.scripts[index];
                        return _buildScriptTile(context, theme, script);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptTile(BuildContext context, ThemeData theme, ScriptEntity script) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)), // Slate 100
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => scriptStore.setEditingScript(script),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        script.name,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B), // Slate 800
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (script.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          script.description,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: const Color(0xFF64748B), // Slate 500
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Play/Stop Button
                Observer(
                  builder: (_) => IconButton(
                    onPressed: () {
                      if (terminalStore.isExecuting) {
                        terminalStore.stopAll();
                      } else {
                        terminalStore.runScript(script);
                      }
                    },
                    icon: Icon(
                      terminalStore.isExecuting
                          ? Icons.stop_circle_rounded
                          : Icons.play_arrow_rounded,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: terminalStore.isExecuting
                        ? Colors.redAccent
                        : const Color(0xFF10B981), // Emerald
                    tooltip: terminalStore.isExecuting ? 'Dừng script' : 'Chạy script',
                  ),
                ),
                const SizedBox(width: 8),
                _buildScriptActions(context, theme, script),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScriptActions(BuildContext context, ThemeData theme, ScriptEntity script) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => scriptStore.setEditingScript(script),
          icon: const Icon(Icons.edit_rounded, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _showDeleteConfirm(context, script),
          icon: const Icon(Icons.delete_outline_rounded, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.error.withValues(alpha: 0.6),
        ),
      ],
    );
  }

  void _showDeleteConfirm(BuildContext context, ScriptEntity script) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa script "${script.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              scriptStore.deleteScript(script.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
