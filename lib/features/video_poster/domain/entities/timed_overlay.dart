import 'dart:typed_data';

class TimedOverlay {
  final Uint8List bytes;
  final double startTime;
  final double? endTime;
  final bool isAnimated;
  final String animationInType;
  final double animationInDuration;
  final String animationOutType;
  final double animationOutDuration;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  const TimedOverlay({
    required this.bytes,
    required this.startTime,
    this.endTime,
    this.isAnimated = false,
    this.animationInType = 'none',
    this.animationInDuration = 0.1,
    this.animationOutType = 'none',
    this.animationOutDuration = 0.1,
    this.x = 0.5,
    this.y = 0.5,
    this.width = 0.0,
    this.height = 0.0,
    this.rotation = 0.0,
  });
}
