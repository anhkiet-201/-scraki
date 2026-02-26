import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/email/domain/entities/email_account.dart';

abstract class ICredentialRemoteDataSource {
  Future<Either<Failure, String>> getRawCredentials();
  Future<Either<Failure, Unit>> saveRawCredentials(String rawText);
  Future<Either<Failure, List<EmailAccount>>> getEmailAccounts();
}

@LazySingleton(as: ICredentialRemoteDataSource)
class CredentialRemoteDataSourceFirebaseImpl
    implements ICredentialRemoteDataSource {
  static const String _collectionName = 'app_configs';
  static const String _documentId = 'email_credentials';
  static const String _fieldKey = 'raw_text';

  final FirebaseFirestore _firestore;

  CredentialRemoteDataSourceFirebaseImpl()
    : _firestore = FirebaseFirestore.instance;

  DocumentReference get _document =>
      _firestore.collection(_collectionName).doc(_documentId);

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
    final rawEither = await getRawCredentials();
    return rawEither.fold((failure) => Left(failure), (rawText) {
      try {
        final accounts = _parseRawCredentials(rawText);
        return Right(accounts);
      } catch (e) {
        return Left(ApiFailure('Failed to parse email credentials: $e'));
      }
    });
  }

  List<EmailAccount> _parseRawCredentials(String rawText) {
    if (rawText.trim().isEmpty) return [];

    final List<EmailAccount> accounts = [];
    final lines = rawText.split('\n');

    for (var line in lines) {
      final parts = line.split('|');
      // Format: id|password|email|recovery_email|refresh_token|client_id ...
      if (parts.length >= 6) {
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
    }
    return accounts;
  }
}
