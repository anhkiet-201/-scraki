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
                'A03 FETCH $startCount:$currentMessageCount (INTERNALDATE BODY.PEEK[HEADER.FIELDS (SUBJECT)] BODY.PEEK[TEXT])\r\n',
              );

              String? currentSubject;
              DateTime? currentInternalDate;
              final currentBody = StringBuffer();

              void submitParsedMessage() {
                if (currentSubject != null && !controller.isClosed) {
                  var rawBody = currentBody.toString();

                  // 1. Tách phần HTML nếu là email multipart
                  String processedBody = rawBody;
                  if (rawBody.contains('Content-Type:') ||
                      rawBody.contains('boundary=')) {
                    processedBody = _extractHtmlPart(rawBody);
                  }

                  // 2. Decode Quoted-Printable và trim
                  final decodedBody =
                      _decodeQuotedPrintable(processedBody).trim();
                  final otp = _extractOtp(decodedBody);

                  controller.add(
                    Right(
                      EmailMessage(
                        subject: currentSubject!,
                        body: decodedBody,
                        otp: otp,
                        receivedAt: currentInternalDate ?? DateTime.now(),
                      ),
                    ),
                  );
                }
                currentSubject = null;
                currentInternalDate = null;
                currentBody.clear();
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

                  // Parse INTERNALDATE if present in this line
                  // Format: INTERNALDATE "19-Mar-2026 16:30:00 +0700"
                  final dateMatch = RegExp(r'INTERNALDATE "([^"]+)"')
                      .firstMatch(line);
                  if (dateMatch != null) {
                    final dateStr = dateMatch.group(1)!;
                    // IMAP date format: 19-Mar-2026 16:30:00 +0700
                    // Let's try a simple parsing or use intl if needed
                    try {
                      // DateTime.parse expects ISO format, so we might need a custom parser
                      // but dart's DateTime can often handle common formats or we can use a more robust regex
                      currentInternalDate = _parseImapDate(dateStr);
                    } catch (_) {}
                  }
                  continue;
                }

                if (line.trim().startsWith('Subject:')) {
                  currentSubject = line.replaceFirst('Subject:', '').trim();
                } else if (!line.startsWith('*') &&
                    !line.startsWith(')') &&
                    !line.contains('FETCH') &&
                    !line.contains('BODY[')) {
                  currentBody.writeln(line);
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

  String _decodeQuotedPrintable(String input) {
    if (!input.contains('=')) return input;
    try {
      // 1. Xử lý nối dòng (soft line break)
      final text = input.replaceAll('=\r\n', '').replaceAll('=\n', '');

      final bytes = <int>[];
      int i = 0;
      while (i < text.length) {
        if (text[i] == '=' && i + 2 < text.length) {
          final hex = text.substring(i + 1, i + 3);
          final byte = int.tryParse(hex, radix: 16);
          if (byte != null) {
            bytes.add(byte);
            i += 3;
            continue;
          }
        }
        // Thêm byte của ký tự hiện tại (UTF-8)
        bytes.addAll(utf8.encode(text[i]));
        i++;
      }

      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return input;
    }
  }

  String? _extractOtp(String text) {
    // 1. Loại bỏ các thẻ HTML để tránh gây nhiễu boundary check
    final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // 2. Tìm các ứng viên (4-8 chữ số, có thể có dấu cách hoặc gạch ngang)
    // Ví dụ: 123456, 123-456, 123 456
    final otpRegex = RegExp(r'\b(\d{2,4}[- ]?\d{2,4})\b');
    final matches = otpRegex.allMatches(cleanText);

    if (matches.isEmpty) return null;

    final candidates = matches.map((m) {
      final raw = m.group(0)!;
      final clean = raw.replaceAll(RegExp(r'[- ]'), '');
      return (raw: raw, clean: clean, start: m.start);
    }).where((c) => c.clean.length >= 4 && c.clean.length <= 8).toList();

    if (candidates.isEmpty) return null;

    // 3. Hệ thống tính điểm để tìm mã khả thi nhất
    double calculateScore(String clean, int start) {
      double score = 0;

      // Độ dài phổ biến: 6 số (+10), 4 số (+5)
      if (clean.length == 6) {
        score += 10;
      } else if (clean.length == 4) {
        score += 5;
      }

      // Kiểm tra từ khóa trong phạm vi gần (40 ký tự xung quanh)
      final contextStart = (start - 40).clamp(0, cleanText.length);
      final contextEnd = (start + 40).clamp(0, cleanText.length);
      final context = cleanText.substring(contextStart, contextEnd).toLowerCase();

      if (context.contains('otp') ||
          context.contains('mã') ||
          context.contains('verification') ||
          context.contains('xác thực')) {
        score += 20;
      }
      if (context.contains('code') || context.contains('là:')) {
        score += 15;
      }

      // Hình phạt cho các số giống năm (2020-2030) nếu là 4 số
      if (clean.length == 4) {
        final val = int.tryParse(clean);
        if (val != null && val >= 2020 && val <= 2030) {
          score -= 15;
        }
      }

      return score;
    }

    // Sắp xếp theo điểm giảm dần
    candidates.sort((a, b) {
      final scoreA = calculateScore(a.clean, a.start);
      final scoreB = calculateScore(b.clean, b.start);
      return scoreB.compareTo(scoreA);
    });

    return candidates.first.clean;
  }

  DateTime? _parseImapDate(String dateStr) {
    // Format: 19-Mar-2026 16:30:00 +0700
    try {
      final months = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12
      };

      final parts = dateStr.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) return null;

      final dateParts = parts[0].split('-');
      if (dateParts.length < 3) return null;

      final day = int.parse(dateParts[0]);
      final month = months[dateParts[1]] ?? 1;
      final year = int.parse(dateParts[2]);

      final timeParts = parts[1].split(':');
      if (timeParts.length < 3) return null;
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);

      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }

  String _extractHtmlPart(String body) {
    try {
      // 1. Tìm phần text/html trong email multipart
      if (!body.toLowerCase().contains('text/html')) return body;

      final htmlParts = body
          .split(RegExp(r'Content-Type:\s*text/html', caseSensitive: false));
      if (htmlParts.length < 2) return body;

      // Lấy phần sau Content-Type: text/html
      var content = htmlParts[1];

      // 2. Loại bỏ các header con (nếu có) bằng cách tìm dòng trống đầu tiên (\r\n\r\n hoặc \n\n)
      final doubleNewline = RegExp(r'(\r?\n){2}');
      final match = doubleNewline.firstMatch(content);
      if (match != null) {
        content = content.substring(match.end);
      }

      // 3. Cắt đến boundary tiếp theo (thường bắt đầu bằng --)
      final boundaryIndex = content.indexOf('\n--');
      if (boundaryIndex != -1) {
        content = content.substring(0, boundaryIndex);
      }

      return content;
    } catch (_) {
      return body;
    }
  }
}
