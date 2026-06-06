import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/core/auth/domain/repositories/i_app_auth_repository.dart';

@lazySingleton
class SignInAnonymouslyUseCase {
  final IAppAuthRepository _repository;

  SignInAnonymouslyUseCase(this._repository);

  Future<Either<Failure, Unit>> call() {
    return _repository.signInAnonymously();
  }
}
