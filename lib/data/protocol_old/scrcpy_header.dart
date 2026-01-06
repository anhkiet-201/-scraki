class ScrcpyHeader {
  final String deviceName;
  final int width;
  final int height;

  const ScrcpyHeader({
    required this.deviceName,
    required this.width,
    required this.height,
  });

  @override
  String toString() =>
      'ScrcpyHeader(name: $deviceName, size: ${width}x$height)';
}
