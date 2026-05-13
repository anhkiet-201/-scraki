import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/script/presentation/stores/terminal_store.dart';

class TerminalHeader extends StatelessWidget {
  final TerminalStore store;

  const TerminalHeader({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Observer(
            builder: (_) => Tooltip(
              message: store.isTiledView ? 'Chế độ gộp' : 'Chế độ lưới',
              child: IconButton(
                onPressed: store.toggleTiledView,
                icon: Icon(
                  store.isTiledView
                      ? Icons.view_headline_rounded
                      : Icons.grid_view_rounded,
                  size: 18,
                  color: store.isTiledView
                      ? theme.colorScheme.primary
                      : const Color(0xFF64748B),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: store.clearTerminal,
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
}
