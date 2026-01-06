import 'package:flutter/material.dart';
import 'package:scraki/core/utils/scrcpy_input_serializer.dart';

class DeviceTouchOverlay extends StatelessWidget {
  final Size originalScreenSize;
  final void Function(int x, int y, int action) onInputEvent;
  final Widget child;

  const DeviceTouchOverlay({
    super.key,
    required this.originalScreenSize,
    required this.onInputEvent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) =>
          _handlePointer(context, e, TouchControlMessage.actionDown),
      onPointerMove: (e) =>
          _handlePointer(context, e, TouchControlMessage.actionMove),
      onPointerUp: (e) =>
          _handlePointer(context, e, TouchControlMessage.actionUp),
      onPointerCancel: (e) =>
          _handlePointer(context, e, TouchControlMessage.actionUp),
      child: child,
    );
  }

  void _handlePointer(BuildContext context, PointerEvent event, int action) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = box.globalToLocal(event.position);
    final widgetSize = box.size;

    // Normalization Logic
    final double scaleX = originalScreenSize.width / widgetSize.width;
    final double scaleY = originalScreenSize.height / widgetSize.height;

    final int realX = (localPosition.dx * scaleX).toInt().clamp(
      0,
      originalScreenSize.width.toInt(),
    );
    final int realY = (localPosition.dy * scaleY).toInt().clamp(
      0,
      originalScreenSize.height.toInt(),
    );

    onInputEvent(realX, realY, action);
  }
}
