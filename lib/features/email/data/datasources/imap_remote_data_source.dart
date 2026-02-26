import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/email/domain/entities/email_message.dart';

abstract class IImapRemoteDataSource {
  Stream<Either<Failure, EmailMessage>> streamLatestEmails({
    required String email,
    required String clientId,
    required String refreshToken,
  });
}

@LazySingleton(as: IImapRemoteDataSource)
class ImapRemoteDataSourceImpl implements IImapRemoteDataSource {
  @override
  Stream<Either<Failure, EmailMessage>> streamLatestEmails({
    required String email,
    required String clientId,
    required String refreshToken,
  }) async* {
    try {
      final accessToken = await _getAccessToken(
        clientId: clientId,
        refreshToken: refreshToken,
      );

      yield* _streamFromImap(email: email, accessToken: accessToken);
    } catch (e) {
      yield Left(ApiFailure('IMAP Connection failed: $e'));
    }
  }

  Future<String> _getAccessToken({
    required String clientId,
    required String refreshToken,
  }) async {
    final res = await http.post(
      Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('TOKEN ERROR: ${res.body}');
    }

    return jsonDecode(res.body)['access_token'] as String;
  }

  String _buildXoauth2(String email, String accessToken) {
    final raw = 'user=$email\u0001auth=Bearer $accessToken\u0001\u0001';
    return base64Encode(utf8.encode(raw));
  }

  Stream<Either<Failure, EmailMessage>> _streamFromImap({
    required String email,
    required String accessToken,
  }) async* {
    SecureSocket? socket;
    try {
      socket = await SecureSocket.connect(
        'outlook.office365.com',
        993,
        onBadCertificate: (_) => true,
      );

      final StreamIterator<String> reader = StreamIterator(
        socket
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter()),
      );

      await reader.moveNext();

      final xoauth2 = _buildXoauth2(email, accessToken);
      socket.write('A01 AUTHENTICATE XOAUTH2 $xoauth2\r\n');

      while (await reader.moveNext()) {
        final line = reader.current;
        if (line.startsWith('A01 OK')) break;
        if (line.startsWith('A01 NO') || line.startsWith('A01 BAD')) {
          yield Left(ApiFailure('IMAP Auth Failed: $line'));
          return;
        }
        if (line.startsWith('+')) {
          socket.write('\r\n');
        }
      }

      // We will create a loop to poll every 5 seconds for new emails.
      final otpRegex = RegExp(r'\b\d{4,8}\b');
      int? lastMessageCount;

      while (true) {
        socket.write('A02 SELECT INBOX\r\n');
        int? currentMessageCount;

        while (await reader.moveNext()) {
          final line = reader.current;
          if (line.contains('EXISTS')) {
            final parts = line.split(' ');
            if (parts.length > 1) {
              currentMessageCount = int.tryParse(parts[1]);
            }
          }
          if (line.startsWith('A02 OK')) break;
          if (line.startsWith('A02 NO')) {
            yield Left(ApiFailure('Select Inbox Failed: $line'));
            return;
          }
        }

        if (currentMessageCount != null && currentMessageCount > 0) {
          if (lastMessageCount == null ||
              currentMessageCount > lastMessageCount) {
            // Fetch subject of the latest message
            socket.write(
              'A03 FETCH $currentMessageCount BODY[HEADER.FIELDS (SUBJECT)]\r\n',
            );
            String? subject;
            String? foundOtp;

            while (await reader.moveNext()) {
              final line = reader.current;
              if (line.startsWith('A03 OK')) break;

              if (line.trim().startsWith('Subject:')) {
                subject = line.replaceFirst('Subject:', '').trim();
                final match = otpRegex.firstMatch(line);
                if (match != null) {
                  foundOtp = match.group(0);
                }
              }
            }

            // FETCH body even if OTP is not found yet
            socket.write('A04 FETCH $currentMessageCount BODY[TEXT]\r\n');
            bool readingBody = false;

            while (await reader.moveNext()) {
              final line = reader.current;
              if (line.startsWith('A04 OK')) break;

              if (line.contains('BODY[TEXT]')) {
                readingBody = true;
                continue;
              }

              if (readingBody && foundOtp == null) {
                final match = otpRegex.firstMatch(line);
                if (match != null) {
                  foundOtp = match.group(0);
                }
              }
            }

            if (subject != null) {
              yield Right(
                EmailMessage(
                  subject: subject,
                  otp: foundOtp,
                  receivedAt: DateTime.now(),
                ),
              );
            }
            lastMessageCount = currentMessageCount;
          }
        }

        await Future<void>.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      yield Left(ApiFailure('Stream IMAP Error: $e'));
    } finally {
      try {
        socket?.write('A05 LOGOUT\r\n');
        await socket?.close();
      } catch (_) {}
    }
  }
}
