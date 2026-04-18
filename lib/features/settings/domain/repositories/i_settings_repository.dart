import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/settings/domain/entities/settings_entity.dart';

abstract class ISettingsRepository {
  Future<Either<Failure, SettingsEntity>> getSettings();

  Future<Either<Failure, Unit>> saveSettings(SettingsEntity settings);
}
