import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart' hide Action;
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/core/stores/device_manager_store.dart';
import 'package:scraki/features/script/presentation/stores/script_management_store.dart';
import 'package:scraki/features/script/presentation/stores/terminal_store.dart';
import 'package:scraki/features/script/presentation/widgets/script_editor_panel.dart';
import 'package:scraki/features/script/presentation/widgets/script_header.dart';
import 'package:scraki/features/script/presentation/widgets/device_sidebar.dart';
import 'package:scraki/features/script/presentation/widgets/script_sidebar.dart';
import 'package:scraki/features/script/presentation/widgets/terminal_view.dart';
import 'package:scraki/features/script/presentation/widgets/tiled_terminal_panel.dart';

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
  late final ScriptManagementStore _scriptStore;
  late final TerminalStore _terminalStore;
  late final DeviceManagerStore _deviceManagerStore;
  
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _terminalFocusNode = FocusNode();
  ReactionDisposer? _scrollDisposer;

  @override
  void initState() {
    super.initState();
    _scriptStore = inject<ScriptManagementStore>();
    _terminalStore = inject<TerminalStore>();
    _deviceManagerStore = inject<DeviceManagerStore>();
    
    _scriptStore.loadScripts();
    
    _commandController.addListener(() {
      if (_commandController.text != _terminalStore.commandInput) {
        _terminalStore.setCommandInput(_commandController.text);
      }
    });
  }

  @override
  void dispose() {
    _commandController.dispose();
    _terminalFocusNode.dispose();
    _scrollDisposer?.call();
    _scriptStore.dispose();
    _terminalStore.dispose();
    super.dispose();
  }

  void _navigateHistory(bool up) {
    _terminalStore.navigateHistory(up);
    _commandController.text = _terminalStore.commandInput;
    _commandController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commandController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  ScriptHeader(store: _terminalStore),
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
                                child: DeviceSidebar(
                                  deviceManagerStore: _deviceManagerStore,
                                  terminalStore: _terminalStore,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                flex: 3,
                                child: ScriptSidebar(
                                  scriptStore: _scriptStore,
                                  terminalStore: _terminalStore,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Main: High-Performance Terminal / IDE Editor
                        Expanded(
                          child: Observer(
                            builder: (_) {
                              if (_scriptStore.editingScript != null) {
                                return ScriptEditorPanel(store: _scriptStore);
                              }

                              return _terminalStore.isTiledView
                                  ? TiledTerminalPanel(
                                      store: _terminalStore,
                                      commandController: _commandController,
                                      terminalFocusNode: _terminalFocusNode,
                                    )
                                  : TerminalView(
                                      store: _terminalStore,
                                      commandController: _commandController,
                                      terminalFocusNode: _terminalFocusNode,
                                    );
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
}
