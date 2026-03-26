import 'package:flutter/material.dart';

class FloatingResizeHandle extends StatelessWidget {
  final void Function(DragUpdateDetails) onResizeUpdate;

  const FloatingResizeHandle({super.key, required this.onResizeUpdate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanUpdate: onResizeUpdate,
      child: Container(
        height: 16,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        child: Center(
          child: Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
