// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_email_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SettingsEmailStore on _SettingsEmailStore, Store {
  late final _$isLoadingAtom = Atom(
    name: '_SettingsEmailStore.isLoading',
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
    name: '_SettingsEmailStore.errorMessage',
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

  late final _$rawCredentialsAtom = Atom(
    name: '_SettingsEmailStore.rawCredentials',
    context: context,
  );

  @override
  String get rawCredentials {
    _$rawCredentialsAtom.reportRead();
    return super.rawCredentials;
  }

  @override
  set rawCredentials(String value) {
    _$rawCredentialsAtom.reportWrite(value, super.rawCredentials, () {
      super.rawCredentials = value;
    });
  }

  late final _$loadCredentialsAsyncAction = AsyncAction(
    '_SettingsEmailStore.loadCredentials',
    context: context,
  );

  @override
  Future<void> loadCredentials() {
    return _$loadCredentialsAsyncAction.run(() => super.loadCredentials());
  }

  late final _$saveCredentialsAsyncAction = AsyncAction(
    '_SettingsEmailStore.saveCredentials',
    context: context,
  );

  @override
  Future<void> saveCredentials() {
    return _$saveCredentialsAsyncAction.run(() => super.saveCredentials());
  }

  late final _$_SettingsEmailStoreActionController = ActionController(
    name: '_SettingsEmailStore',
    context: context,
  );

  @override
  void updateCredentialsLocally(String text) {
    final _$actionInfo = _$_SettingsEmailStoreActionController.startAction(
      name: '_SettingsEmailStore.updateCredentialsLocally',
    );
    try {
      return super.updateCredentialsLocally(text);
    } finally {
      _$_SettingsEmailStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
errorMessage: ${errorMessage},
rawCredentials: ${rawCredentials}
    ''';
  }
}
