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
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border(
            bottom: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ).top,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.drag_handle_rounded,
              size: 20,
              color: colorScheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withValues(alpha: 0.9),
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.5),
                  hoverColor: colorScheme.error.withValues(alpha: 0.1),
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
