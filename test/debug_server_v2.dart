import 'dart:io';
import 'dart:convert';
import 'package:scraki/core/utils/logger.dart';

const serial = '192.168.1.20:5555';
const serverRemote = '/data/local/tmp/scrcpy-server.jar';
const localPort = 61556;

void main() async {
  logger.i('--- Debugging Scrcpy Server v2.0 ---');

  // 1. Setup Tunnel
  await Process.run('adb', [
    '-s',
    serial,
    'forward',
    'tcp:$localPort',
    'localabstract:scrcpy',
  ]);

  // 2. Run Server (Positional Args)
  final args = [
    '2.0',
    'info',
    '0',
    '8000000',
    '60',
    '-1',
    'true',
    '-',
    'true',
    '0',
    'false',
    'true',
    '-',
    '-',
    'false',
    'true',
    'true',
    'true',
    'true',
  ];

  final cmd =
      'CLASSPATH=$serverRemote app_process / com.genymobile.scrcpy.Server ${args.join(' ')}';
  logger.i('Launching: $cmd');
  final serverProc = await Process.start('adb', ['-s', serial, 'shell', cmd]);

  serverProc.stderr
      .transform(utf8.decoder)
      .listen((d) => logger.e('SRV_ERR: $d'));

  // 3. Connect
  await Future<void>.delayed(Duration(seconds: 1));
  try {
    final socket = await Socket.connect('127.0.0.1', localPort);
    logger.i('Socket connected.');

    int byteCount = 0;
    socket.listen((data) {
      byteCount += data.length;
      if (byteCount < 100) {
        logger.d(
          'DATA (Hex): ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
        );
      }
      if (byteCount > 1000) {
        logger.i('SUCCESS: Stream flowing (v2.0)!');
        socket.close();
        serverProc.kill();
        exit(0);
      }
    });
  } catch (e) {
    logger.e('Connect failed', error: e);
    serverProc.kill();
  }
}
