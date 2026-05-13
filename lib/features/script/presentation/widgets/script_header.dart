import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/features/script/presentation/stores/script_store.dart';

class ScriptHeader extends StatelessWidget {
  final ScriptStore store;

  const ScriptHeader({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                color: store.isExecuting
                    ? Colors.amber
                    : const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (store.isExecuting
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
              store.isExecuting ? 'ĐANG CHẠY' : 'SẴN SÀNG',
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
}
