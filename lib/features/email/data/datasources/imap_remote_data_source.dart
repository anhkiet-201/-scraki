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
  }) {
    late StreamController<Either<Failure, EmailMessage>> controller;
    bool isCancelled = false;
    SecureSocket? socket;

    controller = StreamController<Either<Failure, EmailMessage>>(
      onCancel: () async {
        isCancelled = true;
        try {
          socket?.write('A05 LOGOUT\r\n');
          await socket?.close();
        } catch (_) {}
        await controller.close();
      },
    );

    Future<void> startPolling() async {
      try {
        socket = await SecureSocket.connect(
          'outlook.office365.com',
          993,
          onBadCertificate: (_) => true,
        );

        if (isCancelled) return;

        final StreamIterator<String> reader = StreamIterator(
          socket!
              .cast<List<int>>()
              .transform(utf8.decoder)
              .transform(const LineSplitter()),
        );

        await reader.moveNext();
        if (isCancelled) return;

        final xoauth2 = _buildXoauth2(email, accessToken);
        socket!.write('A01 AUTHENTICATE XOAUTH2 $xoauth2\r\n');

        while (await reader.moveNext()) {
          if (isCancelled) return;
          final line = reader.current;
          if (line.startsWith('A01 OK')) break;
          if (line.startsWith('A01 NO') || line.startsWith('A01 BAD')) {
            if (!controller.isClosed) {
              controller.add(Left(ApiFailure('IMAP Auth Failed: $line')));
            }
            return;
          }
          if (line.startsWith('+')) {
            socket!.write('\r\n');
          }
        }

        // We will create a loop to poll every 5 seconds for new emails.
        final otpRegex = RegExp(r'\b\d{4,8}\b');
        int? lastMessageCount;

        while (!isCancelled) {
          socket!.write('A02 SELECT INBOX\r\n');
          int? currentMessageCount;

          while (await reader.moveNext()) {
            if (isCancelled) return;
            final line = reader.current;
            if (line.contains('EXISTS')) {
              final parts = line.split(' ');
              if (parts.length > 1) {
                currentMessageCount = int.tryParse(parts[1]);
              }
            }
            if (line.startsWith('A02 OK')) break;
            if (line.startsWith('A02 NO')) {
              if (!controller.isClosed) {
                controller.add(Left(ApiFailure('Select Inbox Failed: $line')));
              }
              return;
            }
          }

          if (currentMessageCount != null && currentMessageCount > 0) {
            int startCount = currentMessageCount;
            // On the first poll, grab up to 5 messages. On subsequent polls,
            // only grab messages newer than lastMessageCount.
            if (lastMessageCount == null) {
              startCount = (currentMessageCount - 4).clamp(
                1,
                currentMessageCount,
              );
            } else if (currentMessageCount > lastMessageCount) {
              startCount = lastMessageCount + 1;
            } else {
              // No new messages
              startCount = currentMessageCount + 1;
            }

            if (startCount <= currentMessageCount) {
              socket!.write(
                'A03 FETCH $startCount:$currentMessageCount (BODY.PEEK[HEADER.FIELDS (SUBJECT)] BODY.PEEK[TEXT])\r\n',
              );

              String? currentSubject;
              String? currentOtp;

              void submitParsedMessage() {
                if (currentSubject != null && !controller.isClosed) {
                  // Prepend OTP to list to simulate reverse chronological ordering,
                  // but actually the stream output is List UI. The EmailStore inserts at 0 anyway.
                  controller.add(
                    Right(
                      EmailMessage(
                        subject: currentSubject!,
                        otp: currentOtp,
                        receivedAt: DateTime.now(),
                      ),
                    ),
                  );
                }
                currentSubject = null;
                currentOtp = null;
              }

              while (await reader.moveNext()) {
                if (isCancelled) return;
                final line = reader.current;

                if (line.startsWith('A03 OK') ||
                    line.startsWith('A03 NO') ||
                    line.startsWith('A03 BAD')) {
                  submitParsedMessage();
                  break;
                }

                if (line.startsWith('*') && line.contains('FETCH')) {
                  // New message block started
                  submitParsedMessage();
                  continue;
                }

                if (line.trim().startsWith('Subject:')) {
                  currentSubject = line.replaceFirst('Subject:', '').trim();
                }

                if (currentOtp == null) {
                  final match = otpRegex.firstMatch(line);
                  if (match != null) {
                    currentOtp = match.group(0);
                  }
                }
              }
            }
            lastMessageCount = currentMessageCount;
          }

          if (isCancelled) return;
          await Future<void>.delayed(const Duration(seconds: 5));
        }
      } catch (e) {
        if (!isCancelled && !controller.isClosed) {
          controller.add(Left(ApiFailure('Stream IMAP Error: $e')));
        }
      } finally {
        if (!isCancelled) {
          try {
            socket?.write('A05 LOGOUT\r\n');
            await socket?.close();
          } catch (_) {}
        }
        if (!controller.isClosed) {
          await controller.close();
        }
      }
    }

    startPolling();
    return controller.stream;
  }
}
