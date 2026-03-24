// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_nickname_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$DeviceNicknameStore on _DeviceNicknameStore, Store {
  Computed<ObservableMap<String, String>>? _$nicknamesComputed;

  @override
  ObservableMap<String, String> get nicknames =>
      (_$nicknamesComputed ??= Computed<ObservableMap<String, String>>(
        () => super.nicknames,
        name: '_DeviceNicknameStore.nicknames',
      )).value;

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
isLoading: ${isLoading},
errorMessage: ${errorMessage},
nicknames: ${nicknames}
    ''';
  }
}
