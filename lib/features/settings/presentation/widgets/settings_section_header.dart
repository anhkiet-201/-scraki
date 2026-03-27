import 'package:flutter/material.dart';

/// Reusable section header widget with icon and title
class SettingsSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const SettingsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon, 
            size: 16, 
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: isLight ? const Color(0xFF64748B) : Colors.white38,
          ),
        ),
      ],
    );
  }
}
