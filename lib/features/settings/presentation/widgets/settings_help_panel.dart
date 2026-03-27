import 'package:flutter/material.dart';

/// A rich, informative panel to provide context and help for settings.
class SettingsHelpPanel extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const SettingsHelpPanel({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.lightbulb_outline_rounded,
    this.accentColor = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isLight ? accentColor : Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              height: 1.6,
              color: isLight ? const Color(0xFF475569) : Colors.white60,
            ),
          ),
          const SizedBox(height: 16),
          // Subtle "Learn more" or interactive hint
          Row(
            children: [
              Text(
                'Xem chi tiết',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                size: 10,
                color: accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
