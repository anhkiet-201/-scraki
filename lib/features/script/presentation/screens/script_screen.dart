import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/widgets/box_card.dart';
import '../stores/script_store.dart';

class ScriptScreen extends StatefulWidget {
  const ScriptScreen({super.key});

  @override
  State<ScriptScreen> createState() => _ScriptScreenState();
}

class _ScriptScreenState extends State<ScriptScreen> {
  late final ScriptStore _store;
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _terminalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _store = inject<ScriptStore>();
    _store.loadScripts();
  }

  @override
  void dispose() {
    _commandController.dispose();
    _terminalScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalScrollController.hasClients) {
        _terminalScrollController.animateTo(
          _terminalScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          _buildDeviceSelectionBar(theme),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar: Predefined Scripts
                SizedBox(
                  width: 280,
                  child: _buildScriptList(theme),
                ),
                const SizedBox(width: 24),
                // Main: Terminal
                Expanded(
                  child: _buildTerminalView(theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scripts & Terminal',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Thực thi lệnh ADB shell trên nhiều thiết bị đồng thời',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceSelectionBar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TARGET DEVICES',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Observer(
              builder: (_) => Text(
                'Đã chọn: ${_store.selectedSerials.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _store.clearSelection,
              child: const Text('Bỏ chọn tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: Observer(
            builder: (_) {
              final devices = _store.devices;
              if (devices.isEmpty) {
                return Center(
                  child: Text(
                    'Không tìm thấy thiết bị nào đang kết nối',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: devices.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final isSelected = _store.selectedSerials.contains(device.serial);
                  
                  return InkWell(
                    onTap: () => _store.toggleDeviceSelection(device.serial),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                            : theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.smartphone_rounded,
                                size: 16,
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  device.modelName,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            device.serial,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScriptList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREDEFINED SCRIPTS',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Observer(
            builder: (_) {
              if (_store.predefinedScripts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.separated(
                itemCount: _store.predefinedScripts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final script = _store.predefinedScripts[index];
                  return BoxCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => _store.runScript(script),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.terminal_rounded, 
                                    size: 16, 
                                    color: theme.colorScheme.primary
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    script.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              script.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${script.commands.length} LỆNH',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalView(ThemeData theme) {
    const Color terminalBg = Color(0xFFF6F8FA);
    const Color terminalText = Color(0xFF1F2328);
    const Color terminalBorder = Color(0xFFD0D7DE);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CONSOLE OUTPUT',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _store.clearTerminal,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear Console',
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: terminalBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: terminalBorder),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Observer(
                    builder: (_) {
                      _scrollToBottom();
                      return ListView.builder(
                        controller: _terminalScrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _store.terminalOutput.length,
                        itemBuilder: (context, index) {
                          final line = _store.terminalOutput[index];
                          final isCommand = line.startsWith('>>>');
                          final isError = line.contains('Lỗi:');
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: SelectableText(
                              line,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: isCommand 
                                  ? theme.colorScheme.primary 
                                  : isError 
                                    ? Colors.red[700] 
                                    : terminalText,
                                fontSize: 13,
                                fontWeight: isCommand ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1, color: terminalBorder),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        r'$',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF656D76),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commandController,
                          onChanged: _store.setCommandInput,
                          onSubmitted: (_) {
                            _store.executeCurrentCommand();
                            _commandController.clear();
                          },
                          decoration: const InputDecoration(
                            hintText: 'Nhập lệnh ADB shell...',
                            border: InputBorder.none,
                            isDense: true,
                            hintStyle: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Color(0xFF656D76),
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: terminalText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Observer(
                        builder: (_) => IconButton(
                          onPressed: _store.isExecuting 
                              ? null 
                              : () {
                                  _store.executeCurrentCommand();
                                  _commandController.clear();
                                },
                          icon: _store.isExecuting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.play_arrow_rounded),
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
