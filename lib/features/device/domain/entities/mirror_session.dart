import 'package:scraki/features/device/domain/services/device_shell.dart';

class MirrorSession {
  final int width;
  final int height;
  final DeviceShell deviceShell;

  MirrorSession({
    required this.width,
    required this.height,
    required this.deviceShell,
  });
}
