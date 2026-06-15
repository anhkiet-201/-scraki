import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/email/domain/entities/email_account.dart';
import 'package:scraki/features/email/domain/entities/email_message.dart';
import 'package:scraki/features/email/domain/entities/paginated_email_result.dart';

abstract class IEmailRepository {
  Future<Either<Failure, String>> getRawCredentials();
  Future<Either<Failure, Unit>> saveRawCredentials(String rawText);
  Future<Either<Failure, List<EmailAccount>>> getEmailAccounts();

  /// Lấy danh sách tài khoản có phân trang và tìm kiếm
  Future<Either<Failure, PaginatedEmailResult>> fetchEmailAccountsPaginated({
    int limit = 50,
    String? lastUpdate,
    String? searchQuery,
  });

  Future<Either<Failure, Unit>> addEmailAccount(EmailAccount account);
  Future<Either<Failure, Unit>> updateEmailAccount(EmailAccount account);
  Future<Either<Failure, Unit>> deleteEmailAccount(String email);
  Future<Either<Failure, Unit>> bulkAddEmailAccounts(List<EmailAccount> accounts);

  Stream<Either<Failure, EmailMessage>> streamLatestEmails({
    required EmailAccount account,
  });
}
