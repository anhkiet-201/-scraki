import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final content = await File('RSX669800b5ba8b1b.txt').readAsString();
  final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

  if (lines.isEmpty) return;
  final parts = lines.first.split('|');

  // Format: id|password|email|recovery|refresh_token|client_id
  final email = parts[2].trim();
  final refreshToken = parts[4].trim();
  final clientId = parts[5].trim();

  print('Email: $email');

  // Get Access Token using shell
  final res = await Process.run('curl', [
    '-X',
    'POST',
    'https://login.microsoftonline.com/common/oauth2/v2.0/token',
    '-d',
    'client_id=$clientId',
    '-d',
    'grant_type=refresh_token',
    '-d',
    'refresh_token=$refreshToken',
  ]);

  final tokenData = jsonDecode(res.stdout);
  final accessToken = tokenData['access_token'];

  print('Token received.');

  // Build XOAUTH2
  final raw = 'user=$email\u0001auth=Bearer $accessToken\u0001\u0001';
  final xoauth2 = base64Encode(utf8.encode(raw));

  final socket = await SecureSocket.connect(
    'outlook.office365.com',
    993,
    onBadCertificate: (_) => true,
  );

  final reader = StreamIterator(
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter()),
  );

  await reader.moveNext();
  print('S: ${reader.current}');

  socket.write('A01 AUTHENTICATE XOAUTH2 $xoauth2\r\n');
  print('C: A01 AUTHENTICATE XOAUTH2 ...');

  while (await reader.moveNext()) {
    print('S: ${reader.current}');
    if (reader.current.startsWith('A01 OK')) break;
    if (reader.current.startsWith('A01 NO')) return;
    if (reader.current.startsWith('+')) socket.write('\r\n');
  }

  socket.write('A02 SELECT INBOX\r\n');
  print('C: A02 SELECT INBOX');

  int? messageCount;
  while (await reader.moveNext()) {
    print('S: ${reader.current}');
    if (reader.current.contains('EXISTS')) {
      final p = reader.current.split(' ');
      if (p.length > 1) {
        messageCount = int.tryParse(p[1]);
      }
    }
    if (reader.current.startsWith('A02 OK')) break;
  }

  if (messageCount != null && messageCount > 0) {
    socket.write('A03 FETCH $messageCount BODY[HEADER.FIELDS (SUBJECT)]\r\n');
    print('C: A03 FETCH $messageCount BODY[HEADER.FIELDS (SUBJECT)]');

    while (await reader.moveNext()) {
      print('S: ${reader.current}');
      if (reader.current.startsWith('A03 OK')) break;
    }
  } else {
    print('No messages found explicitly from SELECT command EXISTS line.');
  }

  socket.write('A04 LOGOUT\r\n');
  socket.close();
}
