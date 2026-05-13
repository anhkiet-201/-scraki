import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scraki/features/script/presentation/stores/terminal_store.dart';
import 'package:scraki/features/script/presentation/widgets/terminal_header.dart';
import 'package:scraki/features/script/presentation/widgets/tiled_log_view.dart';

class TiledTerminalPanel extends StatelessWidget {
  final TerminalStore store;
  final TextEditingController commandController;
  final FocusNode terminalFocusNode;

  const TiledTerminalPanel({
    super.key,
    required this.store,
    required this.commandController,
    required this.terminalFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      controller: commandController,
                      focusNode: terminalFocusNode,
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
                        hintText: 'Nhập lệnh ADB cho TẤT CẢ thiết bị...',
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
}
