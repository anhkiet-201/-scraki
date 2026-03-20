import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';
import '../entities/auth_token.dart';

abstract class IAuthRepository {
  Future<Either<Failure, List<AuthToken>>> getAuthTokens(
    String groupCollection,
    String serial,
  );
  Future<Either<Failure, Unit>> saveAuthTokens(
    String groupCollection,
    String serial,
    List<AuthToken> tokens,
  );
  Future<Either<Failure, Unit>> addAuthToken(
    String groupCollection,
    String serial,
    AuthToken token,
  );
  Future<Either<Failure, Unit>> deleteAuthToken(
    String groupCollection,
    String serial,
    String id,
  );
}
