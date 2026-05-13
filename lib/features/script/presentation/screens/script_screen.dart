import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart' hide Action;
import 'package:scraki/core/mixins/di_mixin.dart';
import 'package:scraki/features/script/presentation/stores/script_store.dart';
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
    _store.dispose();
    super.dispose();
  }

  void _navigateHistory(bool up) {
    _store.navigateHistory(up);
    _commandController.text = _store.commandInput;
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
                  ScriptHeader(store: _store),
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
                                child: DeviceSidebar(store: _store),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                flex: 3,
                                child: ScriptSidebar(store: _store),
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
                                  ? TiledTerminalPanel(
                                      store: _store,
                                      commandController: _commandController,
                                      terminalFocusNode: _terminalFocusNode,
                                    )
                                  : TerminalView(
                                      store: _store,
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
