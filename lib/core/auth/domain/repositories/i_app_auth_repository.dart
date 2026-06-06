import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';

abstract class IAppAuthRepository {
  Future<Either<Failure, Unit>> signInAnonymously();
  bool get isAuthenticated;
}
