import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';
import '../entities/auth_token.dart';

abstract class IAuthRepository {
  Future<Either<Failure, List<AuthToken>>> getAuthTokens();
  Future<Either<Failure, Unit>> saveAuthTokens(List<AuthToken> tokens);
  Future<Either<Failure, Unit>> addAuthToken(AuthToken token);
  Future<Either<Failure, Unit>> deleteAuthToken(String id);
}
