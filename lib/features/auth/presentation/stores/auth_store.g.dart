// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AuthStore on _AuthStoreBase, Store {
  late final _$tokensAtom = Atom(
    name: '_AuthStoreBase.tokens',
    context: context,
  );

  @override
  ObservableList<AuthToken> get tokens {
    _$tokensAtom.reportRead();
    return super.tokens;
  }

  @override
  set tokens(ObservableList<AuthToken> value) {
    _$tokensAtom.reportWrite(value, super.tokens, () {
      super.tokens = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_AuthStoreBase.isLoading',
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
    name: '_AuthStoreBase.errorMessage',
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

  late final _$secondsRemainingAtom = Atom(
    name: '_AuthStoreBase.secondsRemaining',
    context: context,
  );

  @override
  int get secondsRemaining {
    _$secondsRemainingAtom.reportRead();
    return super.secondsRemaining;
  }

  @override
  set secondsRemaining(int value) {
    _$secondsRemainingAtom.reportWrite(value, super.secondsRemaining, () {
      super.secondsRemaining = value;
    });
  }

  late final _$currentCodesAtom = Atom(
    name: '_AuthStoreBase.currentCodes',
    context: context,
  );

  @override
  ObservableMap<String, String> get currentCodes {
    _$currentCodesAtom.reportRead();
    return super.currentCodes;
  }

  @override
  set currentCodes(ObservableMap<String, String> value) {
    _$currentCodesAtom.reportWrite(value, super.currentCodes, () {
      super.currentCodes = value;
    });
  }

  late final _$loadTokensAsyncAction = AsyncAction(
    '_AuthStoreBase.loadTokens',
    context: context,
  );

  @override
  Future<void> loadTokens() {
    return _$loadTokensAsyncAction.run(() => super.loadTokens());
  }

  late final _$addTokenAsyncAction = AsyncAction(
    '_AuthStoreBase.addToken',
    context: context,
  );

  @override
  Future<void> addToken(String name, String issuer, String secret) {
    return _$addTokenAsyncAction.run(
      () => super.addToken(name, issuer, secret),
    );
  }

  late final _$deleteTokenAsyncAction = AsyncAction(
    '_AuthStoreBase.deleteToken',
    context: context,
  );

  @override
  Future<void> deleteToken(String id) {
    return _$deleteTokenAsyncAction.run(() => super.deleteToken(id));
  }

  late final _$captureFromScreenAsyncAction = AsyncAction(
    '_AuthStoreBase.captureFromScreen',
    context: context,
  );

  @override
  Future<void> captureFromScreen(String serial) {
    return _$captureFromScreenAsyncAction.run(
      () => super.captureFromScreen(serial),
    );
  }

  late final _$_AuthStoreBaseActionController = ActionController(
    name: '_AuthStoreBase',
    context: context,
  );

  @override
  void init() {
    final _$actionInfo = _$_AuthStoreBaseActionController.startAction(
      name: '_AuthStoreBase.init',
    );
    try {
      return super.init();
    } finally {
      _$_AuthStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _updateCodes() {
    final _$actionInfo = _$_AuthStoreBaseActionController.startAction(
      name: '_AuthStoreBase._updateCodes',
    );
    try {
      return super._updateCodes();
    } finally {
      _$_AuthStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
tokens: ${tokens},
isLoading: ${isLoading},
errorMessage: ${errorMessage},
secondsRemaining: ${secondsRemaining},
currentCodes: ${currentCodes}
    ''';
  }
}
