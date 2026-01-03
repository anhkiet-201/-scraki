// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mirroring_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MirroringStore on _MirroringStore, Store {
  Computed<double>? _$deviceAspectRatioComputed;

  @override
  double get deviceAspectRatio =>
      (_$deviceAspectRatioComputed ??= Computed<double>(
        () => super.deviceAspectRatio,
        name: '_MirroringStore.deviceAspectRatio',
      )).value;
  Computed<bool>? _$isFloatingVisibleComputed;

  @override
  bool get isFloatingVisible => (_$isFloatingVisibleComputed ??= Computed<bool>(
    () => super.isFloatingVisible,
    name: '_MirroringStore.isFloatingVisible',
  )).value;

  late final _$activeSessionsAtom = Atom(
    name: '_MirroringStore.activeSessions',
    context: context,
  );

  @override
  ObservableMap<String, MirrorSession> get activeSessions {
    _$activeSessionsAtom.reportRead();
    return super.activeSessions;
  }

  @override
  set activeSessions(ObservableMap<String, MirrorSession> value) {
    _$activeSessionsAtom.reportWrite(value, super.activeSessions, () {
      super.activeSessions = value;
    });
  }

  late final _$floatingSerialAtom = Atom(
    name: '_MirroringStore.floatingSerial',
    context: context,
  );

  @override
  String? get floatingSerial {
    _$floatingSerialAtom.reportRead();
    return super.floatingSerial;
  }

  @override
  set floatingSerial(String? value) {
    _$floatingSerialAtom.reportWrite(value, super.floatingSerial, () {
      super.floatingSerial = value;
    });
  }

  late final _$_MirroringStoreActionController = ActionController(
    name: '_MirroringStore',
    context: context,
  );

  @override
  void toggleFloating(String? serial) {
    final _$actionInfo = _$_MirroringStoreActionController.startAction(
      name: '_MirroringStore.toggleFloating',
    );
    try {
      return super.toggleFloating(serial);
    } finally {
      _$_MirroringStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
activeSessions: ${activeSessions},
floatingSerial: ${floatingSerial},
deviceAspectRatio: ${deviceAspectRatio},
isFloatingVisible: ${isFloatingVisible}
    ''';
  }
}
