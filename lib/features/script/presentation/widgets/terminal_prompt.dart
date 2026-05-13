import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scraki/features/script/presentation/stores/script_store.dart';

class TerminalPrompt extends StatelessWidget {
  final ScriptStore store;
  final TextEditingController commandController;
  final FocusNode terminalFocusNode;

  const TerminalPrompt({
    super.key,
    required this.store,
    required this.commandController,
    required this.terminalFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                controller: commandController,
                focusNode: terminalFocusNode,
                autofocus: true,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    store.executeCurrentCommand();
                    commandController.clear();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (terminalFocusNode.canRequestFocus) {
                        terminalFocusNode.requestFocus();
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
                  suffixIcon: store.hasActiveExecution
                      ? IconButton(
                          icon: const Icon(
                            Icons.stop_circle_rounded,
                            color: Colors.redAccent,
                            size: 24,
                          ),
                          tooltip: 'Dừng tất cả',
                          onPressed: () => store.stopAll(),
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
}
