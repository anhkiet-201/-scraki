import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/email/domain/entities/email_account.dart';
import 'package:scraki/features/email/domain/entities/paginated_email_result.dart';

abstract class ICredentialRemoteDataSource {
  Future<Either<Failure, String>> getRawCredentials();
  Future<Either<Failure, Unit>> saveRawCredentials(String rawText);
  Future<Either<Failure, List<EmailAccount>>> getEmailAccounts();

  // Thao tác Collection mới
  Future<Either<Failure, PaginatedEmailResult>> fetchEmailAccountsPaginated({
    int limit = 50,
    String? lastUpdate,
    String? searchQuery,
  });
  Future<Either<Failure, Unit>> addEmailAccount(EmailAccount account);
  Future<Either<Failure, Unit>> updateEmailAccount(EmailAccount account);
  Future<Either<Failure, Unit>> deleteEmailAccount(String email);
  Future<Either<Failure, Unit>> bulkAddEmailAccounts(List<EmailAccount> accounts);
}

@LazySingleton(as: ICredentialRemoteDataSource)
class CredentialRemoteDataSourceFirebaseImpl
    implements ICredentialRemoteDataSource {
  static const String _collectionName = 'app_configs';
  static const String _documentId = 'email_credentials';
  static const String _fieldKey = 'raw_text';

  // Collection mới cho từng tài khoản riêng lẻ
  static const String _accountsCollection = 'email_accounts';

  final FirebaseFirestore _firestore;

  CredentialRemoteDataSourceFirebaseImpl()
    : _firestore = FirebaseFirestore.instance;

  DocumentReference get _document =>
      _firestore.collection(_collectionName).doc(_documentId);

  CollectionReference get _accountsRef =>
      _firestore.collection(_accountsCollection);

  @override
  Future<Either<Failure, String>> getRawCredentials() async {
    try {
      final snapshot = await _document.get();
      if (!snapshot.exists) {
        return const Right('');
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      final rawText = data?[_fieldKey] as String? ?? '';
      return Right(rawText);
    } catch (e) {
      return Left(
        ApiFailure('Failed to get email credentials from Firebase: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> saveRawCredentials(String rawText) async {
    try {
      await _document.set({
        _fieldKey: rawText,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const Right(unit);
    } catch (e) {
      return Left(
        ApiFailure('Failed to save email credentials to Firebase: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<EmailAccount>>> getEmailAccounts() async {
    // Ưu tiên lấy từ Collection mới. Nếu trống, có thể fallback parser cũ hoặc load toàn bộ
    // Để tương thích ngược, chúng ta vẫn hỗ trợ parse từ Raw Text nếu cần migration.
    // Nhưng xu hướng mới sẽ là fetch từ collection.
    try {
      final snapshot = await _accountsRef.orderBy('updated_at', descending: true).get();
      if (snapshot.docs.isNotEmpty) {
        return Right(
          snapshot.docs
              .map((doc) =>
                  EmailAccount.fromFirestore(doc.data() as Map<String, dynamic>))
              .toList(),
        );
      }

      // Fallback fallback: Lấy từ raw text nếu collection trống (phục vụ migration)
      final rawEither = await getRawCredentials();
      return rawEither.fold((failure) => Left(failure), (rawText) {
        final accounts = _parseRawCredentials(rawText);
        return Right(accounts);
      });
    } catch (e) {
      return Left(ApiFailure('Failed to fetch accounts: $e'));
    }
  }

  Future<Either<Failure, PaginatedEmailResult>> fetchEmailAccountsPaginated({
    int limit = 50,
    String? lastUpdate,
    String? searchQuery,
  }) async {
    try {
      Query query = _accountsRef.orderBy('updated_at', descending: true);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final search = searchQuery.trim().toLowerCase();
        query = query.where('email', isGreaterThanOrEqualTo: search).where(
          'email',
          isLessThanOrEqualTo: '$search\uf8ff',
        );
      }

      if (lastUpdate != null) {
        query = query.startAfter([lastUpdate]);
      }

      final snapshot = await query.limit(limit).get();
      final accounts = snapshot.docs
          .map((doc) =>
              EmailAccount.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      String? nextCursor;
      if (snapshot.docs.isNotEmpty) {
        final lastDocData = snapshot.docs.last.data() as Map<String, dynamic>;
        nextCursor = lastDocData['updated_at'] as String?;
      }

      return Right(PaginatedEmailResult(
        accounts: accounts,
        lastUpdate: nextCursor,
      ));
    } catch (e) {
      return Left(ApiFailure('Failed to fetch paginated accounts: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> addEmailAccount(EmailAccount account) async {
    try {
      await _accountsRef.doc(account.docId).set(account.toFirestore());
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to add account: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateEmailAccount(EmailAccount account) async {
    try {
      await _accountsRef.doc(account.docId).update(account.toFirestore());
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to update account: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteEmailAccount(String email) async {
    try {
      final docId = email.trim().toLowerCase().replaceAll('.', '_');
      await _accountsRef.doc(docId).delete();
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to delete account: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> bulkAddEmailAccounts(
    List<EmailAccount> accounts,
  ) async {
    try {
      // Firebase Batch có giới hạn 500 operations
      for (var i = 0; i < accounts.length; i += 500) {
        final batch = _firestore.batch();
        final chunk = accounts.sublist(
          i,
          i + 500 > accounts.length ? accounts.length : i + 500,
        );

        for (var acc in chunk) {
          batch.set(
            _accountsRef.doc(acc.docId),
            acc.toFirestore(),
            SetOptions(merge: true),
          );
        }
        await batch.commit();
      }
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to bulk add accounts: $e'));
    }
  }

  List<EmailAccount> _parseRawCredentials(String rawText) {
    if (rawText.trim().isEmpty) return [];

    final List<EmailAccount> accounts = [];
    final lines = rawText.split(RegExp(r'\r?\n'));

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split('|');

      try {
        if (parts.length == 5) {
          accounts.add(
            EmailAccount(
              username: parts[0].trim(),
              password: parts[1].trim(),
              email: parts[2].trim(),
              refreshToken: parts[3].trim(),
              clientId: parts[4].trim(),
            ),
          );
        } else if (parts.length >= 6) {
          accounts.add(
            EmailAccount(
              username: parts[0].trim(),
              password: parts[1].trim(),
              email: parts[2].trim(),
              refreshToken: parts[4].trim(),
              clientId: parts[5].trim(),
            ),
          );
        }
      } catch (e) {
        logger.e('[CredentialDataSource] Error parsing line ${i + 1}: $e');
      }
    }
    return accounts;
  }
}
