import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart' hide Action;
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/widgets/box_card.dart';
import 'package:scraki/core/widgets/mesh_background.dart';
import '../../domain/entities/log_entry.dart';
import '../stores/script_store.dart';
import '../../domain/entities/script_entity.dart';
import '../widgets/script_editor_panel.dart';
import '../widgets/tiled_log_view.dart';

class _HistoryIntent extends Intent {
  const _HistoryIntent(this.up);
  final bool up;
}

class ScriptScreen extends StatefulWidget {
  const ScriptScreen({super.key});

  @override
  State<ScriptScreen> createState() => _ScriptScreenState();
}

class _ScriptScreenState extends State<ScriptScreen> {
  late final ScriptStore _store;
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _terminalScrollController = ScrollController();
  final FocusNode _terminalFocusNode = FocusNode();
  ReactionDisposer? _scrollDisposer;
  
  @override
  void initState() {
    super.initState();
    _store = inject<ScriptStore>();
    _store.loadScripts();
    
    _commandController.addListener(() {
      if (_commandController.text != _store.commandInput) {
        _store.setCommandInput(_commandController.text);
      }
    });

    // Auto-scroll when new logs arrive
    _scrollDisposer = reaction(
      (_) => _store.terminalOutput.length,
      (_) => _scrollToBottom(),
    );
  }

  @override
  void dispose() {
    _commandController.dispose();
    _terminalScrollController.dispose();
    _terminalFocusNode.dispose();
    _scrollDisposer?.call();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_terminalScrollController.hasClients) {
        _terminalScrollController.animateTo(
          _terminalScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _navigateHistory(bool up) {
    _store.navigateHistory(up);
    _commandController.text = _store.commandInput;
    _commandController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commandController.text.length),
    );
  }

  Color _getDeviceColor(String? serial) {
    if (serial == null) return Colors.grey;
    final int hash = serial.hashCode;
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MeshBackground(
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.arrowUp): const _HistoryIntent(true),
          const SingleActivator(LogicalKeyboardKey.arrowDown): const _HistoryIntent(false),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _HistoryIntent: CallbackAction<_HistoryIntent>(
              onInvoke: (intent) => _navigateHistory(intent.up),
            ),
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar: Devices & Scripts
                      SizedBox(
                        width: 300,
                        child: Column(
                          children: [
                            Expanded(flex: 2, child: _buildDeviceSidebar(theme)),
                            const SizedBox(height: 16),
                            Expanded(flex: 3, child: _buildScriptSidebar(theme)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Main: High-Performance Terminal / IDE Editor
                      Expanded(
                        child: Observer(
                          builder: (_) {
                            if (_store.editingScript != null) {
                              return ScriptEditorPanel(store: _store);
                            }
                            
                            return _store.isTiledView 
                                ? _buildTiledTerminalView(theme)
                                : _buildTerminalView(theme);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.terminal_rounded, color: theme.colorScheme.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRUNG TÂM ĐIỀU KHIỂN ADB',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Chạy lệnh shell song song trên nhiều thiết bị Android',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildStatusBar(theme),
      ],
    );
  }

  Widget _buildStatusBar(ThemeData theme) {
    return BoxCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Observer(
        builder: (_) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _store.isExecuting ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_store.isExecuting ? Colors.orange : Colors.green).withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _store.isExecuting ? 'ĐANG CHẠY...' : 'SẴN SÀNG',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSidebar(ThemeData theme) {
    return BoxCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'THIẾT BỊ',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              Observer(
                builder: (_) => Text(
                  '${_store.selectedSerials.length}/${_store.devices.length}',
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSelectionControls(theme),
          const SizedBox(height: 12),
          Expanded(
            child: Observer(
              builder: (_) {
                if (_store.devices.isEmpty) {
                  return const Center(child: Text('Không có thiết bị', style: TextStyle(fontSize: 12)));
                }
                return ListView.separated(
                  itemCount: _store.devices.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final device = _store.devices[index];
                    final color = _getDeviceColor(device.serial);
                    
                    return Observer(
                      builder: (context) {
                        final isSelected = _store.selectedSerials.contains(device.serial);
                        return InkWell(
                          onTap: () => _store.toggleDeviceSelection(device.serial),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? color.withValues(alpha: 0.25) 
                                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? color.withValues(alpha: 0.8) : Colors.transparent,
                                width: 2.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.modelName,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        device.serial,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontSize: 10,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected) 
                                  Icon(Icons.check_circle_rounded, size: 14, color: color),
                              ],
                            ),
                          ),
                        );
                      }
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

  Widget _buildScriptSidebar(ThemeData theme) {
    return BoxCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KỊCH BẢN',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              IconButton(
                onPressed: () => _store.updateEditingScript(
                  name: 'Script mới',
                  description: '',
                  commands: [],
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: theme.colorScheme.primary,
                tooltip: 'Tạo script mới',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Observer(
              builder: (_) {
                if (_store.scripts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có script nào.\nNhấn + để tạo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: _store.scripts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final script = _store.scripts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bolt_rounded, size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  script.name,
                                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              _buildScriptActions(theme, script),
                            ],
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _store.runScript(script),
                            child: Text(
                              script.description,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTiledTerminalView(ThemeData theme) {
    return BoxCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildTerminalHeader(theme),
          Expanded(child: TiledLogView(store: _store)),
          // Sticky Global Command Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Text(
                  r'$',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Observer(
                    builder: (_) => TextField(
                      controller: _commandController,
                      focusNode: _terminalFocusNode,
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _store.executeCurrentCommand();
                          _commandController.clear();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_terminalFocusNode.canRequestFocus) {
                              _terminalFocusNode.requestFocus();
                            }
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Nhập lệnh ADB cho TẤT CẢ thiết bị...',
                        hintStyle: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        suffixIcon: _store.hasActiveExecution
                            ? IconButton(
                                icon: const Icon(Icons.stop_circle_rounded, color: Colors.redAccent, size: 24),
                                tooltip: 'Dừng tất cả',
                                onPressed: () => _store.stopAll(),
                              )
                            : null,
                      ),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(Tất cả)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          const Icon(Icons.code_rounded, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          const Text(
            'BẢNG ĐIỀU KHIỂN',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.0,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Tooltip(
            message: 'Chế độ lưới',
            child: IconButton(
              onPressed: _store.toggleTiledView,
              icon: Icon(
                _store.isTiledView ? Icons.grid_view_rounded : Icons.view_headline_rounded,
                size: 18,
                color: _store.isTiledView ? theme.colorScheme.primary : Colors.grey,
              ),
            ),
          ),
          IconButton(
            onPressed: _store.clearTerminal,
            icon: const Icon(Icons.delete_sweep_rounded, size: 20),
            tooltip: 'Xóa kết quả',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildScriptActions(ThemeData theme, ScriptEntity script) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _store.setEditingScript(script),
          icon: const Icon(Icons.edit_rounded, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _showDeleteConfirm(script),
          icon: const Icon(Icons.delete_outline_rounded, size: 14),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: theme.colorScheme.error.withValues(alpha: 0.6),
        ),
      ],
    );
  }

  void _showDeleteConfirm(ScriptEntity script) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa script "${script.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              _store.deleteScript(script.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalView(ThemeData theme) {
    return BoxCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildTerminalHeader(theme),
          // Log Stream
          Expanded(
            child: Scrollbar(
              controller: _terminalScrollController,
              child: SelectionArea(
                child: Observer(
                  builder: (_) {
                    return ListView.builder(
                      controller: _terminalScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _store.terminalOutput.length + 1,
                      itemBuilder: (context, index) {
                        if (index < _store.terminalOutput.length) {
                          final log = _store.terminalOutput[index];
                          final prevLog = index > 0 ? _store.terminalOutput[index - 1] : null;
                          return _buildLogLine(theme, log, prevLog);
                        } else {
                          return _buildPromptLine(theme);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogLine(ThemeData theme, LogEntry log, [LogEntry? prevLog]) {
    final deviceColor = _getDeviceColor(log.serial);
    
    // Check if we should show the device label
    // Show if: 1. No previous log, 2. Different machine, 3. Different log type (e.g. command vs output)
    final bool showLabel = prevLog == null || 
                           prevLog.serial != log.serial || 
                           prevLog.type != log.type;

    switch (log.type) {
      case LogType.command:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    r'$ ',
                    style: GoogleFonts.firaCode(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      log.message,
                      style: GoogleFonts.firaCode(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (log.deviceCount != null && log.deviceCount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        log.deviceCount == 1 
                            ? '[${log.serial ?? "???"}] ${log.deviceModel ?? "Device"}' 
                            : '${log.deviceCount} thiết bị',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    log.formattedTime,
                    style: GoogleFonts.firaCode(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case LogType.error:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLabel) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  '[${log.serial ?? "SYS"}] ${log.deviceModel ?? "System Error"}',
                  style: GoogleFonts.firaCode(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Text(
                log.message,
                style: GoogleFonts.firaCode(color: Colors.redAccent, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        );
      case LogType.info:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            log.message,
            style: GoogleFonts.firaCode(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
          ),
        );
      case LogType.output:
        final deviceName = log.deviceModel ?? "Device";
        final serial = log.serial ?? "Unknown";
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLabel) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Text(
                  '[$serial] $deviceName',
                  style: GoogleFonts.firaCode(
                    color: deviceColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 1), // Minor indent for output
              child: Text(
                log.message,
                style: GoogleFonts.firaCode(
                  fontSize: 12,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildPromptLine(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 40), // Extra space at bottom
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            r'$',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Observer(
              builder: (_) => TextField(
                controller: _commandController,
                focusNode: _terminalFocusNode,
                autofocus: true,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _store.executeCurrentCommand();
                    _commandController.clear();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_terminalFocusNode.canRequestFocus) {
                        _terminalFocusNode.requestFocus();
                      }
                    });
                  }
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Nhập lệnh ADB shell...',
                  hintStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  suffixIcon: _store.hasActiveExecution
                      ? IconButton(
                          icon: const Icon(Icons.stop_circle_rounded, color: Colors.redAccent, size: 24),
                          tooltip: 'Dừng tất cả',
                          onPressed: () => _store.stopAll(),
                        )
                      : null,
                ),
              style: GoogleFonts.firaCode(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSelectionControls(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              final isAllSelected = _store.selectedSerials.length == _store.devices.length;
              _store.selectAllDevices(!isAllSelected);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Observer(
              builder: (_) {
                final isAllSelected = _store.devices.isNotEmpty && _store.selectedSerials.length == _store.devices.length;
                return Text(
                  isAllSelected ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _showRangeSelectDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Chọn theo lô',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _showRangeSelectDialog() {
    final startController = TextEditingController();
    final endController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn thiết bị theo lô', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập số đuôi IP/Serial (Ví dụ: 20 đến 40)',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Từ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: endController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Đến',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final start = int.tryParse(startController.text) ?? 0;
              final end = int.tryParse(endController.text) ?? 0;
              if (start > 0 && end >= start) {
                _store.selectDevicesByRange(start, end);
                Navigator.pop(context);
              }
            },
            child: const Text('Chọn'),
          ),
        ],
      ),
    );
  }
}
