import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/email/data/datasources/credential_remote_data_source.dart';
import 'package:scraki/features/email/data/datasources/imap_remote_data_source.dart';
import 'package:scraki/features/email/domain/entities/email_account.dart';
import 'package:scraki/features/email/domain/entities/email_message.dart';
import 'package:scraki/features/email/domain/entities/paginated_email_result.dart';
import 'package:scraki/features/email/domain/repositories/i_email_repository.dart';

@LazySingleton(as: IEmailRepository)
class EmailRepositoryImpl implements IEmailRepository {
  final ICredentialRemoteDataSource _credentialDataSource;
  final IImapRemoteDataSource _imapDataSource;

  EmailRepositoryImpl(this._credentialDataSource, this._imapDataSource);

  @override
  Future<Either<Failure, String>> getRawCredentials() async {
    return await _credentialDataSource.getRawCredentials();
  }

  @override
  Future<Either<Failure, Unit>> saveRawCredentials(String rawText) async {
    return await _credentialDataSource.saveRawCredentials(rawText);
  }

  @override
  Future<Either<Failure, List<EmailAccount>>> getEmailAccounts() async {
    return await _credentialDataSource.getEmailAccounts();
  }

  @override
  Future<Either<Failure, PaginatedEmailResult>> fetchEmailAccountsPaginated({
    int limit = 50,
    String? lastUpdate,
    String? searchQuery,
  }) async {
    return await _credentialDataSource.fetchEmailAccountsPaginated(
      limit: limit,
      lastUpdate: lastUpdate,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<Either<Failure, Unit>> addEmailAccount(EmailAccount account) async {
    return await _credentialDataSource.addEmailAccount(account);
  }

  @override
  Future<Either<Failure, Unit>> updateEmailAccount(EmailAccount account) async {
    return await _credentialDataSource.updateEmailAccount(account);
  }

  @override
  Future<Either<Failure, Unit>> deleteEmailAccount(String email) async {
    return await _credentialDataSource.deleteEmailAccount(email);
  }

  @override
  Future<Either<Failure, Unit>> bulkAddEmailAccounts(
    List<EmailAccount> accounts,
  ) async {
    return await _credentialDataSource.bulkAddEmailAccounts(accounts);
  }

  @override
  Stream<Either<Failure, EmailMessage>> streamLatestEmails({
    required String email,
    required String clientId,
    required String refreshToken,
  }) {
    return _imapDataSource.streamLatestEmails(
      email: email,
      clientId: clientId,
      refreshToken: refreshToken,
    );
  }
}
