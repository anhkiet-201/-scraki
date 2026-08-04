import 'dart:async';
import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/email/domain/entities/email_account.dart';
import 'package:scraki/features/email/domain/entities/email_message.dart';

abstract class IImapRemoteDataSource {
  Stream<Either<Failure, EmailMessage>> streamLatestEmails({
    required EmailAccount account,
    void Function(String newAccessToken, String? newRefreshToken)? onTokensUpdated,
  });
}

@LazySingleton(as: IImapRemoteDataSource)
class ImapRemoteDataSourceImpl implements IImapRemoteDataSource {
  @override
  Stream<Either<Failure, EmailMessage>> streamLatestEmails({
    required EmailAccount account,
    void Function(String newAccessToken, String? newRefreshToken)? onTokensUpdated,
  }) async* {
    try {
      String currentAccessToken = account.accessToken ?? '';

      // Chỉ lấy access token mới từ refreshToken nếu trong account chưa có accessToken
      if (currentAccessToken.isEmpty) {
        final tokenResult = await _getAccessToken(
          clientId: account.clientId,
          refreshToken: account.refreshToken,
        );

        currentAccessToken = tokenResult.accessToken;
        onTokensUpdated?.call(
          tokenResult.accessToken,
          tokenResult.newRefreshToken,
        );
      }

      // Poll email qua Microsoft Graph API. Nếu token hết hạn (401), _streamFromGraphApi sẽ tự lấy token mới
      yield* _streamFromGraphApi(
        accessToken: currentAccessToken,
        clientId: account.clientId,
        refreshToken: account.refreshToken,
        onTokensUpdated: onTokensUpdated,
      );
    } catch (e) {
      yield Left(ApiFailure('Email Stream Connection failed: $e'));
    }
  }

  Stream<Either<Failure, EmailMessage>> _streamFromGraphApi({
    required String accessToken,
    required String clientId,
    required String refreshToken,
    void Function(String newAccessToken, String? newRefreshToken)? onTokensUpdated,
  }) async* {
    var activeToken = accessToken;
    final Set<String> seenMessageIds = {};
    final otpRegex = RegExp(r'\b\d{4,8}\b');
    bool isFirstFetch = true;

    while (true) {
      try {
        final res = await http.get(
          Uri.parse(
            'https://graph.microsoft.com/v1.0/me/messages'
            '?\$top=10'
            '&\$orderby=receivedDateTime desc',
          ),
          headers: {
            'Authorization': 'Bearer $activeToken',
          },
        );

        if (res.statusCode == 401) {
          // Token hết hạn -> Tự động xin lại token mới
          logger.w('[Graph API] Access Token expired. Refreshing token...');
          final newTokens = await _getAccessToken(
            clientId: clientId,
            refreshToken: refreshToken,
          );
          activeToken = newTokens.accessToken;
          onTokensUpdated?.call(
            newTokens.accessToken,
            newTokens.newRefreshToken,
          );
          continue;
        }

        if (res.statusCode != 200) {
          yield Left(ApiFailure('GRAPH ERROR ${res.statusCode}: ${res.body}'));
          await Future<void>.delayed(const Duration(seconds: 5));
          continue;
        }

        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final messages = (data['value'] as List? ?? []).cast<Map<String, dynamic>>();

        for (final msg in messages) {
          final id = msg['id'] as String? ?? '';
          if (id.isEmpty || seenMessageIds.contains(id)) continue;
          seenMessageIds.add(id);

          // Nếu lần đầu fetch -> Đánh dấu các mail cũ đã xem để tránh spam
          if (isFirstFetch) {
            continue;
          }

          final subject = msg['subject'] as String? ?? '';
          final bodyContent = (msg['body']?['content'] as String?) ?? '';
          final receivedDateTimeStr = msg['receivedDateTime'] as String?;
          final receivedAt = receivedDateTimeStr != null
              ? DateTime.tryParse(receivedDateTimeStr) ?? DateTime.now()
              : DateTime.now();

          final fullText = '$subject\n$bodyContent';
          final match = otpRegex.firstMatch(fullText);
          final otp = match?.group(0);

          yield Right(
            EmailMessage(
              subject: subject,
              body: bodyContent,
              otp: otp,
              receivedAt: receivedAt,
            ),
          );
        }

        if (isFirstFetch) {
          isFirstFetch = false;
          // Phát ra tin nhắn đầu tiên mới nhất nếu có
          if (messages.isNotEmpty) {
            final msg = messages.first;
            final subject = msg['subject'] as String? ?? '';
            final bodyContent = (msg['body']?['content'] as String?) ?? '';
            final receivedDateTimeStr = msg['receivedDateTime'] as String?;
            final receivedAt = receivedDateTimeStr != null
                ? DateTime.tryParse(receivedDateTimeStr) ?? DateTime.now()
                : DateTime.now();

            final fullText = '$subject\n$bodyContent';
            final match = otpRegex.firstMatch(fullText);
            final otp = match?.group(0);

            yield Right(
              EmailMessage(
                subject: subject,
                body: bodyContent,
                otp: otp,
                receivedAt: receivedAt,
              ),
            );
          }
        }
      } catch (e) {
        logger.e('[Graph API Stream Error] $e');
      }

      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  Future<({String accessToken, String? newRefreshToken})> _getAccessToken({
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
        'scope': 'offline_access Mail.Read',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('TOKEN ERROR: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      accessToken: data['access_token'] as String,
      newRefreshToken: data['refresh_token'] as String?,
    );
  }
}
