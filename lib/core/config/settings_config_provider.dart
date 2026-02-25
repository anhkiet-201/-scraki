import 'package:injectable/injectable.dart';
import 'package:scraki/features/settings/domain/entities/settings_entity.dart';
import 'package:scraki/features/settings/domain/usecases/get_settings_usecase.dart';

/// Config provider that uses domain-layer UseCase to access settings
/// This adheres to Clean Architecture by not depending on presentation layer
@singleton
class SettingsConfigProvider {
  final GetSettingsUseCase _getSettingsUseCase;
  SettingsEntity? _cachedSettings;

  SettingsConfigProvider(this._getSettingsUseCase);

  /// Initialize and cache settings from repository
  Future<void> initialize() async {
    await refresh();
  }

  /// Refresh cached settings from repository
  /// Should be called after settings are saved to update the cache
  Future<void> refresh() async {
    final result = await _getSettingsUseCase.call();
    result.fold(
      (_) => _cachedSettings = SettingsEntity.empty(),
      (settings) => _cachedSettings = settings,
    );
  }

  /// Get AI API Key from cached settings
  String get aiApiKey => _cachedSettings?.aiApiKey ?? '';

  /// Get poster phone number from cached settings
  String get posterPhoneNumber => _cachedSettings?.posterPhoneNumber ?? '';

  /// Get Firestore collection name for device groups
  String get deviceGroupCollection =>
      _cachedSettings?.deviceGroupCollection ?? 'device_groups';
}
