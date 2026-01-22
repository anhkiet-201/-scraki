import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/settings/domain/entities/settings_entity.dart';
import 'package:scraki/features/settings/domain/repositories/i_settings_repository.dart';

/// UseCase to get settings from repository
/// This provides a domain-layer abstraction for accessing settings
class GetSettingsUseCase {
  final ISettingsRepository _repository;

  GetSettingsUseCase(this._repository);

  Future<Either<Failure, SettingsEntity>> call() async {
    return await _repository.getSettings();
  }
}
