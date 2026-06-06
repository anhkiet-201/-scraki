import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/auth/domain/usecases/sign_in_anonymously_usecase.dart';
import 'package:scraki/core/utils/logger.dart';

part 'app_auth_store.g.dart';

@lazySingleton
class AppAuthStore = _AppAuthStoreBase with _$AppAuthStore;

abstract class _AppAuthStoreBase with Store {
  final SignInAnonymouslyUseCase _signInUseCase;

  _AppAuthStoreBase(this._signInUseCase);

  @observable
  bool isAuthenticated = false;

  @observable
  bool isLoading = true;

  @observable
  String? errorMessage;

  @action
  Future<void> signInAnonymously() async {
    isLoading = true;
    errorMessage = null;
    
    final result = await _signInUseCase();
    
    result.fold(
      (failure) {
        isAuthenticated = false;
        errorMessage = failure.message;
        logger.e('SignIn Failed: ${failure.message}');
      },
      (_) {
        isAuthenticated = true;
        logger.i('SignIn Anonymous Success');
      },
    );
    
    isLoading = false;
  }
}
