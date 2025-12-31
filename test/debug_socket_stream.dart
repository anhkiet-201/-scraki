import 'dart:io';
import 'dart:convert';
import 'package:scraki/core/utils/logger.dart';

const serial = '192.168.1.20:5555';
const serverRemote = '/data/local/tmp/scrcpy-server.jar';
const localPort = 61555; // Arbitrary port for testing

void main() async {
  logger.i('--- Debugging Video Socket Stream ---');

  // 1. Setup Tunnel
  logger.i('1. Setting up tunnel forward tcp:$localPort...');
  await Process.run('adb', [
    '-s',
    serial,
    'forward',
    'tcp:$localPort',
    'localabstract:scrcpy',
  ]);

  // 2. Run Server (Key-Value args, Raw Mode)
  final args = [
    '3.3.4',
    'log_level=info',
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
  logger.i('2. Launching Server...');
  final serverProc = await Process.start('adb', ['-s', serial, 'shell', cmd]);

  // Log server output
  serverProc.stdout
      .transform(utf8.decoder)
      .listen((d) => logger.i('SRV_OUT: $d'));
  serverProc.stderr
      .transform(utf8.decoder)
      .listen((d) => logger.e('SRV_ERR: $d'));

  // 3. Connect to Socket
  logger.i('3. Connecting to localhost:$localPort in 1s...');
  await Future<void>.delayed(Duration(seconds: 1));

  try {
    final socket = await Socket.connect('127.0.0.1', localPort);
    logger.i('   Socket Connected!');

    int byteCount = 0;
    socket.listen((data) {
      byteCount += data.length;
      if (byteCount < 100) {
        logger.d(
          'STREAM_DATA (Hex): ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
        );
      }

      if (byteCount > 2000) {
        logger.i('SUCCESS: Received > 2000 bytes of video data.');
        socket.close();
        serverProc.kill();
        Process.run('adb', [
          '-s',
          serial,
          'forward',
          '--remove',
          'tcp:$localPort',
        ]);
        exit(0);
      }
    });
  } catch (e) {
    logger.e('Socket Connection Failed', error: e);
    serverProc.kill();
  }
}
