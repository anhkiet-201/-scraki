import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/email/domain/entities/email_account.dart';
import 'package:scraki/features/email/domain/entities/email_message.dart';

abstract class IEmailRepository {
  Future<Either<Failure, String>> getRawCredentials();
  Future<Either<Failure, Unit>> saveRawCredentials(String rawText);
  Future<Either<Failure, List<EmailAccount>>> getEmailAccounts();
  Stream<Either<Failure, EmailMessage>> streamLatestEmails({
    required String email,
    required String clientId,
    required String refreshToken,
  });
}
