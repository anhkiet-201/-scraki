import 'package:injectable/injectable.dart';
import 'package:scraki/features/settings/domain/repositories/i_settings_repository.dart';
import 'package:scraki/features/settings/domain/usecases/get_settings_usecase.dart';

@module
abstract class SettingsUseCaseModule {
  @injectable
  GetSettingsUseCase getSettingsUseCase(ISettingsRepository repository) =>
      GetSettingsUseCase(repository);
}
