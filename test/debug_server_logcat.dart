import 'dart:io';
import 'dart:convert';
import 'package:scraki/core/utils/logger.dart';

const serial = '192.168.1.20:5555';
const serverLocal = 'assets/server/scrcpy-server.jar';
const serverRemote = '/data/local/tmp/scrcpy-server.jar';

void main() async {
  logger.i('--- Debugging Scrcpy Server Crash (Logcat) ---');

  // 1. Push
  logger.i('1. Pushing server...');
  await Process.run('adb', ['-s', serial, 'push', serverLocal, serverRemote]);

  // 2. Clear Logcat
  await Process.run('adb', ['-s', serial, 'logcat', '-c']);

  // 3. Run Server
  // Using minimal valid args for 3.x
  final args = [
    '3.3.4',
    'log_level=debug',
    // 'tunnel_forward=true', // forcing tunnel might cause immediate exit if socket not found.
    // Let's try WITHOUT tunnel first to see if it starts and waiting for connection?
    // Actually standard mode is "scrcpy-server [ver] [args]".
    // If we want it to listen, we might need different args or it tries to connect back.
    // Let's stick to the args we used that caused the crash, to see WHY it crashed.
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
  logger.i('Running: $cmd');

  final process = await Process.start('adb', ['-s', serial, 'shell', cmd]);

  process.stderr.transform(utf8.decoder).listen((d) => logger.e('STDERR: $d'));

  // Wait for it to die
  await Future<void>.delayed(Duration(seconds: 2));

  logger.i('--- Fetching Logcat (App Crash) ---');
  final logcat = await Process.run('adb', [
    '-s',
    serial,
    'logcat',
    '-d',
    '-s',
    'scrcpy',
    'AndroidRuntime',
    'DEBUG',
  ]);
  logger.i(logcat.stdout);

  process.kill();
  exit(0);
}
