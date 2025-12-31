import 'dart:io';
import 'dart:convert';
import 'package:scraki/core/utils/logger.dart';

const serial = '192.168.1.20:5555';
const serverRemote = '/data/local/tmp/scrcpy-server.jar';

void main() async {
  logger.i('--- Debugging Scrcpy Server (Minimal Args) ---');

  final args = [
    '3.3.4',
    'log_level=debug',
    'video_bit_rate=8000000',
    'max_fps=60',
    'tunnel_forward=true',
    'control=true',
    'audio=false', // Explicitly disable audio
    'scid=00000000', // Provide SCID
    'send_device_meta=false',
    'send_frame_meta=false',
    'cleanup=true',
  ];

  final cmd =
      'CLASSPATH=$serverRemote app_process / com.genymobile.scrcpy.Server ${args.join(' ')}';
  logger.i('Cmd: $cmd');

  final process = await Process.start('adb', ['-s', serial, 'shell', cmd]);

  process.stdout
      .transform(utf8.decoder)
      .listen((data) => logger.i('STDOUT: $data'));
  process.stderr
      .transform(utf8.decoder)
      .listen((data) => logger.e('STDERR: $data'));

  await Future<void>.delayed(Duration(seconds: 4));
  process.kill();
}
