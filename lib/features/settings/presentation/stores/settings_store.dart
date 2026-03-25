import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/config/settings_config_provider.dart';
import 'package:scraki/core/di/injection.dart';
import 'package:scraki/features/settings/domain/entities/settings_entity.dart';
import 'package:scraki/features/settings/domain/repositories/i_settings_repository.dart';

part 'settings_store.g.dart';

@singleton
class SettingsStore = _SettingsStore with _$SettingsStore;

abstract class _SettingsStore with Store {
  final ISettingsRepository _repository;

  _SettingsStore(this._repository);

  // ===== Observables =====
  @observable
  SettingsEntity? settings;

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  // ===== Computed =====
  @computed
  String get aiApiKey => settings?.aiApiKey ?? '';

  @computed
  String get posterPhoneNumber => settings?.posterPhoneNumber ?? '';

  @computed
  String get deviceGroupCollection =>
      settings?.deviceGroupCollection ?? 'device_groups';

  // ===== Actions =====
  @action
  Future<void> loadSettings() async {
    isLoading = true;
    errorMessage = null;

    final result = await _repository.getSettings();

    result.fold(
      (failure) {
        errorMessage = 'Failed to load settings: ${failure.message}';
        settings = SettingsEntity.empty();
      },
      (loadedSettings) {
        settings = loadedSettings;
      },
    );

    isLoading = false;
  }

  @action
  void updateApiKey(String newKey) {
    settings ??= SettingsEntity.empty();
    settings = settings!.copyWith(aiApiKey: newKey);
    errorMessage = null;
  }

  @action
  void updatePhoneNumber(String newPhone) {
    settings ??= SettingsEntity.empty();
    settings = settings!.copyWith(posterPhoneNumber: newPhone);
    errorMessage = null;
  }

  @action
  void updateDeviceGroupCollection(String collection) {
    settings ??= SettingsEntity.empty();
    settings = settings!.copyWith(deviceGroupCollection: collection);
    errorMessage = null;
  }

  @action
  Future<void> saveSettings() async {
    // Validation
    if (settings == null) {
      errorMessage = 'No settings to save';
      return;
    }

    if (settings!.aiApiKey.trim().isEmpty) {
      errorMessage = 'AI API Key cannot be empty';
      return;
    }

    if (settings!.posterPhoneNumber.trim().isEmpty) {
      errorMessage = 'Phone Number cannot be empty';
      return;
    }

    isLoading = true;
    errorMessage = null;

    final result = await _repository.saveSettings(settings!);

    // Handle result và refresh config nếu thành công
    await result.fold(
      (failure) async {
        errorMessage = 'Failed to save settings: ${failure.message}';
      },
      (_) async {
        errorMessage = null;

        // Refresh SettingsConfigProvider cache để AppConfig được cập nhật
        try {
          final configProvider = getIt<SettingsConfigProvider>();
          await configProvider.refresh();
        } catch (e) {
          // Ignore if provider not available
        }
      },
    );

    isLoading = false;
  }

  /// Dispose method để cleanup khi cần
  void dispose() {
    // Cleanup nếu cần thiết
  }
}
