import 'dart:io';
import 'dart:convert';

const serial = '192.168.1.20:5555';
const serverRemote = '/data/local/tmp/scrcpy-server.jar';

void main() async {
  print('--- Debugging Scrcpy Server (Minimal Args) ---');

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
  print('Cmd: $cmd');

  final process = await Process.start('adb', ['-s', serial, 'shell', cmd]);

  process.stdout
      .transform(utf8.decoder)
      .listen((data) => print('STDOUT: $data'));
  process.stderr
      .transform(utf8.decoder)
      .listen((data) => print('STDERR: $data'));

  await Future.delayed(Duration(seconds: 4));
  process.kill();
}
