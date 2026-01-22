import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/settings/data/models/settings_model.dart';
import 'package:scraki/features/settings/domain/entities/settings_entity.dart';
import 'package:scraki/features/settings/domain/repositories/i_settings_repository.dart';

@LazySingleton(as: ISettingsRepository)
class SettingsRepositoryImpl implements ISettingsRepository {
  static const String boxName = 'app_settings';
  static const String settingsKey = 'user_settings';
  bool _isInitialized = false;

  /// Private method: Khởi tạo Adapter và mở Box
  Future<Box<SettingsModel>> _getBox() async {
    if (!_isInitialized) {
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SettingsModelAdapter());
      }
      _isInitialized = true;
    }
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<SettingsModel>(boxName);
    }
    return Hive.box<SettingsModel>(boxName);
  }

  @override
  Future<Either<Failure, SettingsEntity>> getSettings() async {
    try {
      final box = await _getBox();
      final model = box.get(settingsKey);

      // Nếu chưa có settings, trả về empty
      if (model == null) {
        return Right(SettingsEntity.empty());
      }

      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to load settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(SettingsEntity settings) async {
    try {
      final box = await _getBox();
      final model = SettingsModel.fromEntity(settings);
      await box.put(settingsKey, model);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to save settings: $e'));
    }
  }
}
