import 'package:flutter/material.dart';

/// Header bar for Settings screen
class SettingsHeaderBar extends StatelessWidget {
  const SettingsHeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : Colors.black.withValues(alpha: 0.2),
        border: null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings_rounded,
              size: 24,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isLight ? const Color(0xFF1E293B) : Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Configure your application preferences',
                style: TextStyle(
                  fontSize: 11,
                  color: isLight ? const Color(0xFF64748B) : Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
