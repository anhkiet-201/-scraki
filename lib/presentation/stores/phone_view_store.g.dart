// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_view_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PhoneViewStore on _PhoneViewStore, Store {
  Computed<bool>? _$isLoadingComputed;

  @override
  bool get isLoading => (_$isLoadingComputed ??= Computed<bool>(
    () => super.isLoading,
    name: '_PhoneViewStore.isLoading',
  )).value;
  Computed<bool>? _$isFloatingVisibleComputed;

  @override
  bool get isFloatingVisible => (_$isFloatingVisibleComputed ??= Computed<bool>(
    () => super.isFloatingVisible,
    name: '_PhoneViewStore.isFloatingVisible',
  )).value;

  late final _$devicesAtom = Atom(
    name: '_PhoneViewStore.devices',
    context: context,
  );

  @override
  ObservableList<DeviceEntity> get devices {
    _$devicesAtom.reportRead();
    return super.devices;
  }

  @override
  set devices(ObservableList<DeviceEntity> value) {
    _$devicesAtom.reportWrite(value, super.devices, () {
      super.devices = value;
    });
  }

  late final _$selectedSerialsAtom = Atom(
    name: '_PhoneViewStore.selectedSerials',
    context: context,
  );

  @override
  ObservableSet<String> get selectedSerials {
    _$selectedSerialsAtom.reportRead();
    return super.selectedSerials;
  }

  @override
  set selectedSerials(ObservableSet<String> value) {
    _$selectedSerialsAtom.reportWrite(value, super.selectedSerials, () {
      super.selectedSerials = value;
    });
  }

  late final _$isBroadcastingModeAtom = Atom(
    name: '_PhoneViewStore.isBroadcastingMode',
    context: context,
  );

  @override
  bool get isBroadcastingMode {
    _$isBroadcastingModeAtom.reportRead();
    return super.isBroadcastingMode;
  }

  @override
  set isBroadcastingMode(bool value) {
    _$isBroadcastingModeAtom.reportWrite(value, super.isBroadcastingMode, () {
      super.isBroadcastingMode = value;
    });
  }

  late final _$loadDevicesFutureAtom = Atom(
    name: '_PhoneViewStore.loadDevicesFuture',
    context: context,
  );

  @override
  ObservableFuture<void>? get loadDevicesFuture {
    _$loadDevicesFutureAtom.reportRead();
    return super.loadDevicesFuture;
  }

  @override
  set loadDevicesFuture(ObservableFuture<void>? value) {
    _$loadDevicesFutureAtom.reportWrite(value, super.loadDevicesFuture, () {
      super.loadDevicesFuture = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_PhoneViewStore.errorMessage',
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

  late final _$floatingSerialAtom = Atom(
    name: '_PhoneViewStore.floatingSerial',
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

  late final _$activeSessionsAtom = Atom(
    name: '_PhoneViewStore.activeSessions',
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

  late final _$loadDevicesAsyncAction = AsyncAction(
    '_PhoneViewStore.loadDevices',
    context: context,
  );

  @override
  Future<void> loadDevices() {
    return _$loadDevicesAsyncAction.run(() => super.loadDevices());
  }

  late final _$startMirroringAsyncAction = AsyncAction(
    '_PhoneViewStore.startMirroring',
    context: context,
  );

  @override
  Future<MirrorSession> startMirroring(String serial) {
    return _$startMirroringAsyncAction.run(() => super.startMirroring(serial));
  }

  late final _$stopMirroringAsyncAction = AsyncAction(
    '_PhoneViewStore.stopMirroring',
    context: context,
  );

  @override
  Future<void> stopMirroring(String serial) {
    return _$stopMirroringAsyncAction.run(() => super.stopMirroring(serial));
  }

  late final _$connectTcpAsyncAction = AsyncAction(
    '_PhoneViewStore.connectTcp',
    context: context,
  );

  @override
  Future<void> connectTcp(String ip, int port) {
    return _$connectTcpAsyncAction.run(() => super.connectTcp(ip, port));
  }

  late final _$disconnectAsyncAction = AsyncAction(
    '_PhoneViewStore.disconnect',
    context: context,
  );

  @override
  Future<void> disconnect(String serial) {
    return _$disconnectAsyncAction.run(() => super.disconnect(serial));
  }

  late final _$_PhoneViewStoreActionController = ActionController(
    name: '_PhoneViewStore',
    context: context,
  );

  @override
  void toggleFloating(String? serial) {
    final _$actionInfo = _$_PhoneViewStoreActionController.startAction(
      name: '_PhoneViewStore.toggleFloating',
    );
    try {
      return super.toggleFloating(serial);
    } finally {
      _$_PhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleBroadcasting() {
    final _$actionInfo = _$_PhoneViewStoreActionController.startAction(
      name: '_PhoneViewStore.toggleBroadcasting',
    );
    try {
      return super.toggleBroadcasting();
    } finally {
      _$_PhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleDeviceSelection(String serial) {
    final _$actionInfo = _$_PhoneViewStoreActionController.startAction(
      name: '_PhoneViewStore.toggleDeviceSelection',
    );
    try {
      return super.toggleDeviceSelection(serial);
    } finally {
      _$_PhoneViewStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
devices: ${devices},
selectedSerials: ${selectedSerials},
isBroadcastingMode: ${isBroadcastingMode},
loadDevicesFuture: ${loadDevicesFuture},
errorMessage: ${errorMessage},
floatingSerial: ${floatingSerial},
activeSessions: ${activeSessions},
isLoading: ${isLoading},
isFloatingVisible: ${isFloatingVisible}
    ''';
  }
}
