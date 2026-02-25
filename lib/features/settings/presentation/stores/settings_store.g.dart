// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SettingsStore on _SettingsStore, Store {
  Computed<String>? _$aiApiKeyComputed;

  @override
  String get aiApiKey => (_$aiApiKeyComputed ??= Computed<String>(
    () => super.aiApiKey,
    name: '_SettingsStore.aiApiKey',
  )).value;
  Computed<String>? _$posterPhoneNumberComputed;

  @override
  String get posterPhoneNumber =>
      (_$posterPhoneNumberComputed ??= Computed<String>(
        () => super.posterPhoneNumber,
        name: '_SettingsStore.posterPhoneNumber',
      )).value;
  Computed<String>? _$deviceGroupCollectionComputed;

  @override
  String get deviceGroupCollection =>
      (_$deviceGroupCollectionComputed ??= Computed<String>(
        () => super.deviceGroupCollection,
        name: '_SettingsStore.deviceGroupCollection',
      )).value;

  late final _$settingsAtom = Atom(
    name: '_SettingsStore.settings',
    context: context,
  );

  @override
  SettingsEntity? get settings {
    _$settingsAtom.reportRead();
    return super.settings;
  }

  @override
  set settings(SettingsEntity? value) {
    _$settingsAtom.reportWrite(value, super.settings, () {
      super.settings = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_SettingsStore.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_SettingsStore.errorMessage',
    context: context,
  );

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$loadSettingsAsyncAction = AsyncAction(
    '_SettingsStore.loadSettings',
    context: context,
  );

  @override
  Future<void> loadSettings() {
    return _$loadSettingsAsyncAction.run(() => super.loadSettings());
  }

  late final _$saveSettingsAsyncAction = AsyncAction(
    '_SettingsStore.saveSettings',
    context: context,
  );

  @override
  Future<void> saveSettings() {
    return _$saveSettingsAsyncAction.run(() => super.saveSettings());
  }

  late final _$_SettingsStoreActionController = ActionController(
    name: '_SettingsStore',
    context: context,
  );

  @override
  void updateApiKey(String newKey) {
    final _$actionInfo = _$_SettingsStoreActionController.startAction(
      name: '_SettingsStore.updateApiKey',
    );
    try {
      return super.updateApiKey(newKey);
    } finally {
      _$_SettingsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updatePhoneNumber(String newPhone) {
    final _$actionInfo = _$_SettingsStoreActionController.startAction(
      name: '_SettingsStore.updatePhoneNumber',
    );
    try {
      return super.updatePhoneNumber(newPhone);
    } finally {
      _$_SettingsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateDeviceGroupCollection(String collection) {
    final _$actionInfo = _$_SettingsStoreActionController.startAction(
      name: '_SettingsStore.updateDeviceGroupCollection',
    );
    try {
      return super.updateDeviceGroupCollection(collection);
    } finally {
      _$_SettingsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
settings: ${settings},
isLoading: ${isLoading},
errorMessage: ${errorMessage},
aiApiKey: ${aiApiKey},
posterPhoneNumber: ${posterPhoneNumber},
deviceGroupCollection: ${deviceGroupCollection}
    ''';
  }
}
