import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/features/email/domain/repositories/i_email_repository.dart';

part 'settings_email_store.g.dart';

@injectable
class SettingsEmailStore = _SettingsEmailStore with _$SettingsEmailStore;

abstract class _SettingsEmailStore with Store {
  final IEmailRepository _repository;

  _SettingsEmailStore(this._repository);

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @observable
  String rawCredentials = '';

  @action
  Future<void> loadCredentials() async {
    isLoading = true;
    errorMessage = null;

    final result = await _repository.getRawCredentials();

    result.fold(
      (failure) {
        errorMessage = 'Failed to load credentials: ${failure.message}';
      },
      (text) {
        rawCredentials = text;
      },
    );

    isLoading = false;
  }

  @action
  void updateCredentialsLocally(String text) {
    rawCredentials = text;
    errorMessage = null;
  }

  @action
  Future<void> saveCredentials() async {
    isLoading = true;
    errorMessage = null;

    final result = await _repository.saveRawCredentials(rawCredentials);

    result.fold(
      (failure) {
        errorMessage = 'Failed to save credentials: ${failure.message}';
      },
      (_) {
        errorMessage = null;
      },
    );

    isLoading = false;
  }
}
