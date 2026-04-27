import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import '../models/auth_token_model.dart';
import '../../domain/entities/auth_token.dart';

abstract class IAuthRemoteDataSource {
  Future<Either<Failure, List<AuthToken>>> getAuthTokens(
    String groupCollection,
    String serial,
  );
  Future<Either<Failure, Unit>> saveAuthTokens(
    String groupCollection,
    String serial,
    List<AuthToken> tokens,
  );
}

@LazySingleton(as: IAuthRemoteDataSource)
class AuthRemoteDataSourceFirebaseImpl implements IAuthRemoteDataSource {
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceFirebaseImpl() : _firestore = FirebaseFirestore.instance;

  DocumentReference _getDocument(String groupCollection, String serial) {
    final safeSerial = serial.replaceAll('.', '_dot_').replaceAll(':', '_colon_');
    return _firestore
        .collection(groupCollection)
        .doc('data')
        .collection('auth_tokens')
        .doc(safeSerial);
  }

  @override
  Future<Either<Failure, List<AuthToken>>> getAuthTokens(
    String groupCollection,
    String serial,
  ) async {
    try {
      final snapshot = await _getDocument(groupCollection, serial).get();
      if (!snapshot.exists) {
        return const Right([]);
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      final tokensList = data?['tokens'] as List<dynamic>? ?? [];
      
      final tokens = tokensList.map((t) {
        // Nếu là String cũ (trong quá trình chuyển đổi hoặc migration)
        if (t is String) {
          return AuthTokenModel.fromRawLine(t);
        }
        // Giả sử sau này ta lưu Map đầy đủ, nhưng hiện tại ta lưu String line
        return AuthTokenModel.fromRawLine(t.toString());
      }).toList();

      return Right(tokens);
    } catch (e) {
      return Left(ApiFailure('Failed to get auth tokens from Firebase: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveAuthTokens(
    String groupCollection,
    String serial,
    List<AuthToken> tokens,
  ) async {
    try {
      final tokenLines = tokens.map((t) => AuthTokenModel.fromEntity(t).toRawLine()).toList();
      
      await _getDocument(groupCollection, serial).set({
        'tokens': tokenLines,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to save auth tokens to Firebase: $e'));
    }
  }
}
