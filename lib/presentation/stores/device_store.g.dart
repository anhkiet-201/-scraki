// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$DeviceStore on _DeviceStore, Store {
  Computed<bool>? _$isLoadingComputed;

  @override
  bool get isLoading => (_$isLoadingComputed ??= Computed<bool>(
    () => super.isLoading,
    name: '_DeviceStore.isLoading',
  )).value;

  late final _$devicesAtom = Atom(
    name: '_DeviceStore.devices',
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
    name: '_DeviceStore.selectedSerials',
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
    name: '_DeviceStore.isBroadcastingMode',
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
    name: '_DeviceStore.loadDevicesFuture',
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
    name: '_DeviceStore.errorMessage',
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

  late final _$loadDevicesAsyncAction = AsyncAction(
    '_DeviceStore.loadDevices',
    context: context,
  );

  @override
  Future<void> loadDevices() {
    return _$loadDevicesAsyncAction.run(() => super.loadDevices());
  }

  late final _$startMirroringAsyncAction = AsyncAction(
    '_DeviceStore.startMirroring',
    context: context,
  );

  @override
  Future<String> startMirroring(String serial) {
    return _$startMirroringAsyncAction.run(() => super.startMirroring(serial));
  }

  late final _$connectTcpAsyncAction = AsyncAction(
    '_DeviceStore.connectTcp',
    context: context,
  );

  @override
  Future<void> connectTcp(String ip, int port) {
    return _$connectTcpAsyncAction.run(() => super.connectTcp(ip, port));
  }

  late final _$disconnectAsyncAction = AsyncAction(
    '_DeviceStore.disconnect',
    context: context,
  );

  @override
  Future<void> disconnect(String serial) {
    return _$disconnectAsyncAction.run(() => super.disconnect(serial));
  }

  late final _$_DeviceStoreActionController = ActionController(
    name: '_DeviceStore',
    context: context,
  );

  @override
  void toggleBroadcasting() {
    final _$actionInfo = _$_DeviceStoreActionController.startAction(
      name: '_DeviceStore.toggleBroadcasting',
    );
    try {
      return super.toggleBroadcasting();
    } finally {
      _$_DeviceStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleDeviceSelection(String serial) {
    final _$actionInfo = _$_DeviceStoreActionController.startAction(
      name: '_DeviceStore.toggleDeviceSelection',
    );
    try {
      return super.toggleDeviceSelection(serial);
    } finally {
      _$_DeviceStoreActionController.endAction(_$actionInfo);
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
isLoading: ${isLoading}
    ''';
  }
}
