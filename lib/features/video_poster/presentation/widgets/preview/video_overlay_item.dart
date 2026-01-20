import 'package:flutter/material.dart';

/// Draggable text overlay item for video preview
///
/// Features:
/// - Draggable positioning
/// - Auto-wrapping text container
/// - Customizable colors and sizing
/// - Mouse cursor feedback
/// - Border highlight
class VideoOverlayItem extends StatelessWidget {
  final String label;
  final double x;
  final double y;
  final String type;
  final BoxConstraints constraints;
  final Color color;
  final double fontSize;
  final void Function(String type, double x, double y) onPositionUpdate;

  const VideoOverlayItem({
    super.key,
    required this.label,
    required this.x,
    required this.y,
    required this.type,
    required this.constraints,
    required this.color,
    required this.fontSize,
    required this.onPositionUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment(x * 2 - 1, y * 2 - 1),
        child: GestureDetector(
          onPanUpdate: (details) {
            final newX = (x + details.delta.dx / constraints.maxWidth).clamp(
              0.0,
              1.0,
            );
            final newY = (y + details.delta.dy / constraints.maxHeight).clamp(
              0.0,
              1.0,
            );
            onPositionUpdate(type, newX, newY);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.move,
            child: Container(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.8),
                  width: 1.5,
                ),
                color: Colors.black45,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    const Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                softWrap: true,
                textAlign: type == 'requirements' || type == 'benefits'
                    ? TextAlign.left
                    : TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
