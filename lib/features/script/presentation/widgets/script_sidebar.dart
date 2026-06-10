import 'dart:async';
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

class ScriptSidebar extends StatefulWidget {
  final ScriptManagementStore scriptStore;
  final TerminalStore terminalStore;

  const ScriptSidebar({
    super.key,
    required this.scriptStore,
    required this.terminalStore,
  });

  @override
  State<ScriptSidebar> createState() => _ScriptSidebarState();
}

class _ScriptSidebarState extends State<ScriptSidebar> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.scriptStore.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.scriptStore.setSearchQuery(query);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    widget.scriptStore.setSearchQuery('');
  }

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
                onPressed: () => widget.scriptStore.updateEditingScript(
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
          // Search Field
          Observer(
            builder: (_) {
              return TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm script...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13), // Slate 400
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20), // Slate 500
                  suffixIcon: widget.scriptStore.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF64748B), size: 18),
                          onPressed: _clearSearch,
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC), // Slate 50
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Observer(
              builder: (_) {
                if (widget.scriptStore.scripts.isEmpty) {
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

                final filtered = widget.scriptStore.filteredScripts;
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Không tìm thấy script phù hợp.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return Observer(
                      builder: (context) {
                        final script = filtered[index];
                        
                        // 1. Tạo core delegate dựa trên tileType
                        ScriptTileDelegate coreDelegate;
                        void onRun(ScriptEntity s, [Map<String, String>? args]) {
                          if (widget.terminalStore.isExecuting) {
                            widget.terminalStore.stopAll();
                          } else {
                            widget.terminalStore.runScript(s, args: args);
                          }
                        }
                        void onDelete(ScriptEntity s, [Map<String, dynamic>? args]) => widget.scriptStore.deleteScript(s.id);
                        void onEdit(ScriptEntity s, [Map<String, dynamic>? args]) => widget.scriptStore.setEditingScript(s);
                        final isExecuting = widget.terminalStore.isExecuting;

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
                                  widget.scriptStore.setEditingScript(script);
                                  widget.scriptStore.updateEditingScript(
                                    commands: [...script.commands, 'echo "$path"'],
                                  );
                                  await widget.scriptStore.saveCurrentScript();
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
