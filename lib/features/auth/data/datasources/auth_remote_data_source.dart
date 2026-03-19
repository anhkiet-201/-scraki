import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import '../models/auth_token_model.dart';
import '../../domain/entities/auth_token.dart';

abstract class IAuthRemoteDataSource {
  Future<Either<Failure, String>> getRawAuthTokens();
  Future<Either<Failure, Unit>> saveRawAuthTokens(String rawText);
  Future<Either<Failure, List<AuthToken>>> getAuthTokens();
}

@LazySingleton(as: IAuthRemoteDataSource)
class AuthRemoteDataSourceFirebaseImpl implements IAuthRemoteDataSource {
  static const String _collectionName = 'app_configs';
  static const String _documentId = 'auth_tokens';
  static const String _fieldKey = 'raw_text';

  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceFirebaseImpl() : _firestore = FirebaseFirestore.instance;

  DocumentReference get _document =>
      _firestore.collection(_collectionName).doc(_documentId);

  @override
  Future<Either<Failure, String>> getRawAuthTokens() async {
    try {
      final snapshot = await _document.get();
      if (!snapshot.exists) {
        return const Right('');
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      final rawText = data?[_fieldKey] as String? ?? '';
      return Right(rawText);
    } catch (e) {
      return Left(ApiFailure('Failed to get auth tokens from Firebase: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveRawAuthTokens(String rawText) async {
    try {
      await _document.set({
        _fieldKey: rawText,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to save auth tokens to Firebase: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AuthToken>>> getAuthTokens() async {
    final rawEither = await getRawAuthTokens();
    return rawEither.fold(
      (failure) => Left(failure),
      (rawText) {
        try {
          if (rawText.trim().isEmpty) return const Right([]);
          final lines = rawText.split('\n');
          final tokens = lines
              .where((line) => line.trim().isNotEmpty)
              .map((line) => AuthTokenModel.fromRawLine(line))
              .toList();
          return Right(tokens);
        } catch (e) {
          return Left(ApiFailure('Failed to parse auth tokens: $e'));
        }
      },
    );
  }
}
