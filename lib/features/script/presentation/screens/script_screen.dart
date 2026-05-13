import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart' hide Action;
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';
import 'package:scraki/features/script/domain/entities/log_entry.dart';
import 'package:scraki/features/script/presentation/stores/script_store.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/script/presentation/widgets/script_editor_panel.dart';
import 'package:scraki/features/script/presentation/widgets/tiled_log_view.dart';

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
  final FocusNode _terminalFocusNode = FocusNode();
  ReactionDisposer? _scrollDisposer;

  @override
  void initState() {
    super.initState();
    _store = inject<ScriptStore>();
    _store.init();
    _store.loadScripts();
    _commandController.addListener(() {
      if (_commandController.text != _store.commandInput) {
        _store.setCommandInput(_commandController.text);
      }
    });
  }

  @override
  void dispose() {
    _commandController.dispose();
    _terminalFocusNode.dispose();
    _scrollDisposer?.call();
    super.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50 - Very light grey
      body: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const _HistoryIntent(true),
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const _HistoryIntent(false),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _HistoryIntent: CallbackAction<_HistoryIntent>(
              onInvoke: (intent) => _navigateHistory(intent.up),
            ),
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                              Expanded(
                                flex: 2,
                                child: _buildDeviceSidebar(theme),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                flex: 3,
                                child: _buildScriptSidebar(theme),
                              ),
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
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.terminal_rounded,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Script Automation',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: const Color(0xFF1E293B), // Slate 800
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Điều khiển thiết bị song song chuyên nghiệp',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B), // Slate 500
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildStatusBar(theme),
        ],
      ),
    );
  }

  Widget _buildStatusBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Observer(
        builder: (_) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _store.isExecuting
                    ? Colors.amber
                    : const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (_store.isExecuting
                                ? Colors.amber
                                : const Color(0xFF10B981))
                            .withValues(alpha: 0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _store.isExecuting ? 'ĐANG CHẠY' : 'SẴN SÀNG',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
                color: const Color(0xFF475569), // Slate 600
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSidebar(ThemeData theme) {
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
                'DEVICES',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: const Color(0xFF64748B), // Slate 500
                ),
              ),
              Observer(
                builder: (_) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_store.selectedSerials.length}/${_store.devices.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSelectionControls(theme),
          const SizedBox(height: 12),
          Expanded(
            child: Observer(
              builder: (_) {
                if (_store.devices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.devices_other_rounded,
                          color: Colors.grey.shade300,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Không có thiết bị',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: _store.devices.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final device = _store.devices[index];
                    final color = _getDeviceColor(device.serial);

                    return Observer(
                      builder: (context) {
                        final isSelected = _store.selectedSerials.contains(
                          device.serial,
                        );
                        return InkWell(
                          onTap: () =>
                              _store.toggleDeviceSelection(device.serial),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.05,
                                    )
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.5,
                                      )
                                    : const Color(0xFFF1F5F9), // Slate 100
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : color.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.modelName,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              fontSize: 12,
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                  : const Color(0xFF1E293B),
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        device.serial,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontSize: 10,
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                        .withValues(alpha: 0.7)
                                                  : const Color(0xFF64748B),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
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

  Widget _buildScriptSidebar(ThemeData theme) {
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
                onPressed: () => _store.updateEditingScript(
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
                if (_store.scripts.isEmpty) {
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
                  itemCount: _store.scripts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return Observer(
                      builder: (context) {
                        final script = _store.scripts[index];
                        return _buildScriptTile(theme, script);
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

  Widget _buildTiledTerminalView(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTerminalHeader(theme),
          Expanded(child: TiledLogView()),
          // Sticky Global Command Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC), // Slate 50
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Text(
                  r'$',
                  style: GoogleFonts.firaCode(
                    fontWeight: FontWeight.bold,
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
                        hintStyle: GoogleFonts.firaCode(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8), // Slate 400
                          fontStyle: FontStyle.italic,
                        ),
                        suffixIcon: _store.hasActiveExecution
                            ? IconButton(
                                icon: const Icon(
                                  Icons.stop_circle_rounded,
                                  color: Colors.redAccent,
                                  size: 24,
                                ),
                                tooltip: 'Dừng tất cả',
                                onPressed: () => _store.stopAll(),
                              )
                            : null,
                      ),
                      style: GoogleFonts.firaCode(
                        fontSize: 13,
                        color: const Color(0xFF1E293B), // Slate 800
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ALL',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC), // Slate 50
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.terminal_rounded,
            size: 18,
            color: Color(0xFF64748B),
          ), // Slate 500
          const SizedBox(width: 12),
          Text(
            'CONSOLE',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: const Color(0xFF64748B), // Slate 500
            ),
          ),
          const Spacer(),
          Tooltip(
            message: _store.isTiledView ? 'Chế độ gộp' : 'Chế độ lưới',
            child: IconButton(
              onPressed: _store.toggleTiledView,
              icon: Icon(
                _store.isTiledView
                    ? Icons.view_headline_rounded
                    : Icons.grid_view_rounded,
                size: 18,
                color: _store.isTiledView
                    ? theme.colorScheme.primary
                    : const Color(0xFF64748B),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _store.clearTerminal,
            icon: const Icon(Icons.delete_sweep_rounded, size: 20),
            tooltip: 'Xóa kết quả',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: const Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptTile(ThemeData theme, ScriptEntity script) {
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
          onTap: () => _store.setEditingScript(script),
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
                // Play Button
                IconButton(
                  onPressed: () => _store.runScript(script),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: const Color(0xFF10B981), // Emerald
                  tooltip: 'Chạy script',
                ),
                const SizedBox(width: 8),
                _buildScriptActions(theme, script),
              ],
            ),
          ),
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTerminalHeader(theme),
          // Log Stream
          Expanded(
            child: SelectionArea(
              child: Observer(
                builder: (_) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _store.terminalOutput.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final log = _store.terminalOutput.reversed
                          .toList()[index];
                      final prevLog = index > 0
                          ? _store.terminalOutput[index - 1]
                          : null;
                      return _buildLogLine(theme, log, prevLog);
                    },
                  );
                },
              ),
            ),
          ),
          _buildPromptLine(theme),
        ],
      ),
    );
  }

  Widget _buildLable(LogEntry log) {
    final deviceColor = _getDeviceColor(log.serial);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        '[${log.serial ?? "SYS"}] ${log.deviceModel ?? "System"}',
        style: GoogleFonts.firaCode(
          color: deviceColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildLogLine(ThemeData theme, LogEntry log, [LogEntry? prevLog]) {
    switch (log.type) {
      case LogType.command:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      log.message,
                      style: GoogleFonts.firaCode(
                        color: const Color(0xFF1E293B), // Slate 800
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (log.deviceCount != null && log.deviceCount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.deviceCount == 1
                            ? '[${log.serial}] ${log.deviceModel ?? "Device"}'
                            : '${log.deviceCount} DEVICCES',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    log.formattedTime,
                    style: GoogleFonts.firaCode(
                      color: const Color(0xFF94A3B8), // Slate 400
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
            _buildLable(log),
            Text(
              log.message,
              style: GoogleFonts.firaCode(
                color: Colors.red.shade700,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        );
      case LogType.info:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLable(log),
            Text(
              '// ${log.message}',
              style: GoogleFonts.firaCode(
                color: const Color(0xFF94A3B8), // Slate 400
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      case LogType.output:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLable(log),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                log.message,
                style: GoogleFonts.firaCode(
                  fontSize: 12,
                  height: 1.6,
                  color: const Color(0xFF334155), // Slate 700
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildPromptLine(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 60, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            r'$',
            style: GoogleFonts.firaCode(
              fontWeight: FontWeight.bold,
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
                  hintStyle: GoogleFonts.firaCode(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8), // Slate 400
                    fontStyle: FontStyle.italic,
                  ),
                  suffixIcon: _store.hasActiveExecution
                      ? IconButton(
                          icon: const Icon(
                            Icons.stop_circle_rounded,
                            color: Colors.redAccent,
                            size: 24,
                          ),
                          tooltip: 'Dừng tất cả',
                          onPressed: () => _store.stopAll(),
                        )
                      : null,
                ),
                style: GoogleFonts.firaCode(
                  fontSize: 13,
                  color: const Color(0xFF1E293B), // Slate 800
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
              final isAllSelected =
                  _store.selectedSerials.length == _store.devices.length;
              _store.selectAllDevices(!isAllSelected);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              foregroundColor: const Color(0xFF475569), // Slate 600
              backgroundColor: Colors.white,
            ),
            child: Observer(
              builder: (_) {
                final isAllSelected =
                    _store.devices.isNotEmpty &&
                    _store.selectedSerials.length == _store.devices.length;
                return Text(
                  isAllSelected ? 'BỎ CHỌN' : 'CHỌN TẤT CẢ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              foregroundColor: const Color(0xFF475569), // Slate 600
              backgroundColor: Colors.white,
            ),
            child: Text(
              'CHỌN LÔ',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _showGroupSelectDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              foregroundColor: const Color(0xFF475569), // Slate 600
              backgroundColor: Colors.white,
            ),
            child: Text(
              'CHỌN NHÓM',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Chọn thiết bị theo lô',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập số thứ tự hoặc số đuôi IP (Ví dụ: 1 đến 50)',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'TỪ',
                      labelStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: endController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'ĐẾN',
                      labelStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'HỦY',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final start = int.tryParse(startController.text);
              final end = int.tryParse(endController.text);
              if (start != null && end != null) {
                _store.selectDevicesByRange(start, end);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'CHỌN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupSelectDialog() {
    final groupStore = inject<DeviceGroupStore>();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Chọn thiết bị theo nhóm',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        content: SizedBox(
          width: 400,
          child: Observer(
            builder: (_) {
              if (groupStore.groups.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Chưa có nhóm nào được định nghĩa.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                itemCount: groupStore.groups.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final group = groupStore.groups[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(group.colorValue),
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Text(
                      '${group.deviceSerials.length} thiết bị',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    onTap: () {
                      _store.selectDevicesByGroup(group.id);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ĐÓNG',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
