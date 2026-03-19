// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_nickname_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$DeviceNicknameStore on _DeviceNicknameStore, Store {
  late final _$nicknamesAtom = Atom(
    name: '_DeviceNicknameStore.nicknames',
    context: context,
  );

  @override
  ObservableMap<String, String> get nicknames {
    _$nicknamesAtom.reportRead();
    return super.nicknames;
  }

  @override
  set nicknames(ObservableMap<String, String> value) {
    _$nicknamesAtom.reportWrite(value, super.nicknames, () {
      super.nicknames = value;
    });
  }

  late final _$isLoadingAtom = Atom(
    name: '_DeviceNicknameStore.isLoading',
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
    name: '_DeviceNicknameStore.errorMessage',
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

  late final _$_startWatchingNicknamesAsyncAction = AsyncAction(
    '_DeviceNicknameStore._startWatchingNicknames',
    context: context,
  );

  @override
  Future<void> _startWatchingNicknames() {
    return _$_startWatchingNicknamesAsyncAction.run(
      () => super._startWatchingNicknames(),
    );
  }

  late final _$saveNicknameAsyncAction = AsyncAction(
    '_DeviceNicknameStore.saveNickname',
    context: context,
  );

  @override
  Future<void> saveNickname(String deviceSerial, String nickname) {
    return _$saveNicknameAsyncAction.run(
      () => super.saveNickname(deviceSerial, nickname),
    );
  }

  @override
  String toString() {
    return '''
nicknames: ${nicknames},
isLoading: ${isLoading},
errorMessage: ${errorMessage}
    ''';
  }
}
