import 'dart:io';
import 'dart:convert';

const serial = '192.168.1.20:5555';
const serverRemote = '/data/local/tmp/scrcpy-server.jar';

void main() async {
  print('--- Debugging Scrcpy Server Crash ---');

  // Verify file exists
  await Process.run('adb', [
    '-s',
    serial,
    'shell',
    'ls',
    '-l',
    serverRemote,
  ]).then((r) => print('Remote file: ${r.stdout}'));

  final args = [
    '3.3.4',
    'log_level=debug', // DEBUG level
    'max_size=0',
    'video_bit_rate=8000000',
    'max_fps=60',
    'tunnel_forward=true',
    'control=true',
    'display_id=0',
    'show_touches=false',
    'stay_awake=true',
    'send_device_meta=false',
    'send_frame_meta=false',
    'power_off_on_close=false',
    'clipboard_autosync=true',
    'downsize_on_error=true',
    'cleanup=true',
    'power_on=true',
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

  await Future.delayed(Duration(seconds: 5));
  process.kill();
}
