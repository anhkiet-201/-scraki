import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/script/presentation/stores/script_management_store.dart';
import 'package:scraki/features/script/presentation/stores/terminal_store.dart';
import 'package:scraki/features/script/presentation/widgets/tiles/script_tile.dart';
import 'package:scraki/features/script/presentation/widgets/tiles/delegates/file_drop_tile_delegate.dart';
import 'package:scraki/features/script/presentation/widgets/tiles/delegates/confirm_tile_delegate.dart';
import 'package:scraki/features/script/presentation/widgets/tiles/delegates/normal_tile_delegate.dart';
import 'package:scraki/features/script/presentation/widgets/tiles/delegates/dialog_tile_delegate.dart';
import 'package:scraki/features/script/presentation/widgets/tiles/delegates/input_tile_delegate.dart';
import 'package:scraki/features/script/presentation/widgets/tiles/script_tile_delegate.dart';

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
                        
                        // 1. Tạo core delegate dựa trên tileType
                        ScriptTileDelegate coreDelegate;
                        void onRun(ScriptEntity s) {
                          if (terminalStore.isExecuting) {
                            terminalStore.stopAll();
                          } else {
                            terminalStore.runScript(s);
                          }
                        }
                        void onDelete(ScriptEntity s) => scriptStore.deleteScript(s.id);
                        void onEdit(ScriptEntity s) => scriptStore.setEditingScript(s);
                        final isExecuting = terminalStore.isExecuting;

                        switch (script.tileType) {
                          case ScriptTileType.normal:
                            coreDelegate = NormalTileDelegate(
                              onRun: onRun,
                              onDelete: onDelete,
                              onEdit: onEdit,
                              isExecuting: isExecuting,
                            );
                          case ScriptTileType.confirm:
                            coreDelegate = ConfirmTileDelegate(
                              onRun: onRun,
                              onDelete: onDelete,
                              onEdit: onEdit,
                              isExecuting: isExecuting,
                            );
                          case ScriptTileType.dialog:
                            coreDelegate = DialogTileDelegate(
                              onRun: onRun,
                              onDelete: onDelete,
                              onEdit: onEdit,
                              isExecuting: isExecuting,
                            );
                          case ScriptTileType.input:
                            coreDelegate = InputTileDelegate(
                              onRun: onRun,
                              onDelete: onDelete,
                              onEdit: onEdit,
                              isExecuting: isExecuting,
                            );
                        }

                        // 2. Bọc trong FileDrop nếu được bật
                        final delegate = script.enableFileDrop
                            ? FileDropTileDelegate(
                                child: coreDelegate,
                                onFileDropped: (path) async {
                                  scriptStore.setEditingScript(script);
                                  scriptStore.updateEditingScript(
                                    commands: [...script.commands, 'echo "$path"'],
                                  );
                                  await scriptStore.saveCurrentScript();
                                },
                              )
                            : coreDelegate;

                        return ScriptTile(
                          script: script,
                          delegate: delegate,
                        );
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
}


