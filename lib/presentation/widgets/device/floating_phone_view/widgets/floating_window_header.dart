import 'package:flutter/material.dart';

class FloatingWindowHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final void Function(DragUpdateDetails) onDragUpdate;

  const FloatingWindowHeader({
    super.key,
    required this.title,
    required this.onClose,
    required this.onDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onPanUpdate: onDragUpdate,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.drag_indicator_rounded,
              size: 18,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  foregroundColor: colorScheme.error.withValues(alpha: 0.8),
                ),
                onPressed: onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
