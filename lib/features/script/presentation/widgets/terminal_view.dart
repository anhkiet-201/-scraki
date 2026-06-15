import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/script/presentation/stores/terminal_store.dart';
import 'package:scraki/features/script/presentation/widgets/terminal_header.dart';
import 'package:scraki/features/script/presentation/widgets/terminal_prompt.dart';
import 'package:scraki/features/script/presentation/widgets/log_line_item.dart';

class TerminalView extends StatelessWidget {
  final TerminalStore store;
  final TextEditingController commandController;
  final FocusNode terminalFocusNode;

  const TerminalView({
    super.key,
    required this.store,
    required this.commandController,
    required this.terminalFocusNode,
  });

  @override
  Widget build(BuildContext context) {
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
          TerminalHeader(store: store),
          // Log Stream
          Expanded(
            child: Observer(
              builder: (_) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: store.terminalOutput.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final log = store.terminalOutput.reversed
                        .toList()[index];
                    final prevLog = index > 0
                        ? store.terminalOutput[index - 1]
                        : null;
                    return SelectionArea(
                      child: LogLineItem(log: log, prevLog: prevLog),
                    );
                  },
                );
              },
            ),
          ),
          TerminalPrompt(
            store: store,
            commandController: commandController,
            terminalFocusNode: terminalFocusNode,
          ),
        ],
      ),
    );
  }
}
