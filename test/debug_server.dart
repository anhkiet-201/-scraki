import 'dart:io';
import 'dart:convert';
import 'package:scraki/core/utils/logger.dart';

const serial = '192.168.1.20:5555'; // Using the active device from previous log
const serverRemote = '/data/local/tmp/scrcpy-server.jar';

void main() async {
  logger.i('--- Debugging Scrcpy Server Launch v3.3.4 (Key-Value Mode) ---');

  // Verify server version string is correct for 3.3.4
  // Server args: [version] [k=v] [k=v] ...
  final args = [
    '3.3.4',
    'log_level=info',
    'max_size=0',
    'video_bit_rate=8000000',
    'max_fps=60',
    'tunnel_forward=true',
    // 'crop=-', // Removed: invalid format
    // Usually if it's key=value, we might not need default placeholders if they are optional.
    // But if the server iterates, maybe we do.
    // Let's guess standard keys.
    'control=true',
    'display_id=0',
    'show_touches=false',
    'stay_awake=true',
    // 'codec_options=-', // Might be complex
    // 'encoder_name=-',
    'power_off_on_close=false',
    'clipboard_autosync=true',
    'downsize_on_error=true',
    'cleanup=true',
    'power_on=true',

    // Some keys might have changed names.
    // video_bit_rate? or just bit_rate?
    // Let's try 'video_bit_rate' as per v2 conventions or 'max_size'.
  ];

  // NOTE: I am not pushing the server again as it should be there.

  final cmd =
      'CLASSPATH=$serverRemote app_process / com.genymobile.scrcpy.Server ${args.join(' ')}';
  logger.i('Running: $cmd');

  final process = await Process.start('adb', ['-s', serial, 'shell', cmd]);

  process.stderr.transform(utf8.decoder).listen((data) {
    logger.e('STDERR: $data');
  });

  int byteCount = 0;
  process.stdout.listen((data) {
    byteCount += data.length;
    if (byteCount < 100) {
      logger.d(
        'STDOUT (Hex): ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
      );
    }
    if (byteCount > 1000) {
      logger.i('Stream is flowing! Received > 1000 bytes.');
      process.kill();
      exit(0);
    }
  });

  await Future<void>.delayed(Duration(seconds: 5));
  logger.w('Timeout. Total bytes received: $byteCount');
  process.kill();
}
