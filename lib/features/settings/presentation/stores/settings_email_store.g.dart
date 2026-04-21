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

  late final _$isPaginatingAtom = Atom(
    name: '_SettingsEmailStore.isPaginating',
    context: context,
  );

  @override
  bool get isPaginating {
    _$isPaginatingAtom.reportRead();
    return super.isPaginating;
  }

  @override
  set isPaginating(bool value) {
    _$isPaginatingAtom.reportWrite(value, super.isPaginating, () {
      super.isPaginating = value;
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

  late final _$accountsAtom = Atom(
    name: '_SettingsEmailStore.accounts',
    context: context,
  );

  @override
  ObservableList<EmailAccount> get accounts {
    _$accountsAtom.reportRead();
    return super.accounts;
  }

  @override
  set accounts(ObservableList<EmailAccount> value) {
    _$accountsAtom.reportWrite(value, super.accounts, () {
      super.accounts = value;
    });
  }

  late final _$searchQueryAtom = Atom(
    name: '_SettingsEmailStore.searchQuery',
    context: context,
  );

  @override
  String get searchQuery {
    _$searchQueryAtom.reportRead();
    return super.searchQuery;
  }

  @override
  set searchQuery(String value) {
    _$searchQueryAtom.reportWrite(value, super.searchQuery, () {
      super.searchQuery = value;
    });
  }

  late final _$hasMoreAtom = Atom(
    name: '_SettingsEmailStore.hasMore',
    context: context,
  );

  @override
  bool get hasMore {
    _$hasMoreAtom.reportRead();
    return super.hasMore;
  }

  @override
  set hasMore(bool value) {
    _$hasMoreAtom.reportWrite(value, super.hasMore, () {
      super.hasMore = value;
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

  late final _$loadInitialAccountsAsyncAction = AsyncAction(
    '_SettingsEmailStore.loadInitialAccounts',
    context: context,
  );

  @override
  Future<void> loadInitialAccounts() {
    return _$loadInitialAccountsAsyncAction.run(
      () => super.loadInitialAccounts(),
    );
  }

  late final _$loadNextPageAsyncAction = AsyncAction(
    '_SettingsEmailStore.loadNextPage',
    context: context,
  );

  @override
  Future<void> loadNextPage() {
    return _$loadNextPageAsyncAction.run(() => super.loadNextPage());
  }

  late final _$setSearchQueryAsyncAction = AsyncAction(
    '_SettingsEmailStore.setSearchQuery',
    context: context,
  );

  @override
  Future<void> setSearchQuery(String query) {
    return _$setSearchQueryAsyncAction.run(() => super.setSearchQuery(query));
  }

  late final _$addAccountAsyncAction = AsyncAction(
    '_SettingsEmailStore.addAccount',
    context: context,
  );

  @override
  Future<void> addAccount(EmailAccount account) {
    return _$addAccountAsyncAction.run(() => super.addAccount(account));
  }

  late final _$updateAccountAsyncAction = AsyncAction(
    '_SettingsEmailStore.updateAccount',
    context: context,
  );

  @override
  Future<void> updateAccount(EmailAccount account) {
    return _$updateAccountAsyncAction.run(() => super.updateAccount(account));
  }

  late final _$deleteAccountAsyncAction = AsyncAction(
    '_SettingsEmailStore.deleteAccount',
    context: context,
  );

  @override
  Future<void> deleteAccount(String email) {
    return _$deleteAccountAsyncAction.run(() => super.deleteAccount(email));
  }

  late final _$bulkImportAsyncAction = AsyncAction(
    '_SettingsEmailStore.bulkImport',
    context: context,
  );

  @override
  Future<void> bulkImport(String rawText) {
    return _$bulkImportAsyncAction.run(() => super.bulkImport(rawText));
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
isPaginating: ${isPaginating},
errorMessage: ${errorMessage},
accounts: ${accounts},
searchQuery: ${searchQuery},
hasMore: ${hasMore},
rawCredentials: ${rawCredentials}
    ''';
  }
}
