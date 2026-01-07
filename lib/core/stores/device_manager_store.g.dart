// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_manager_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$DeviceManagerStore on _DeviceManagerStore, Store {
  Computed<bool>? _$isLoadingComputed;

  @override
  bool get isLoading => (_$isLoadingComputed ??= Computed<bool>(
    () => super.isLoading,
    name: '_DeviceManagerStore.isLoading',
  )).value;

  late final _$devicesAtom = Atom(
    name: '_DeviceManagerStore.devices',
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
    name: '_DeviceManagerStore.selectedSerials',
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
    name: '_DeviceManagerStore.isBroadcastingMode',
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
    name: '_DeviceManagerStore.loadDevicesFuture',
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
    name: '_DeviceManagerStore.errorMessage',
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
    '_DeviceManagerStore.loadDevices',
    context: context,
  );

  @override
  Future<void> loadDevices() {
    return _$loadDevicesAsyncAction.run(() => super.loadDevices());
  }

  late final _$connectTcpAsyncAction = AsyncAction(
    '_DeviceManagerStore.connectTcp',
    context: context,
  );

  @override
  Future<void> connectTcp(String ip, int port) {
    return _$connectTcpAsyncAction.run(() => super.connectTcp(ip, port));
  }

  late final _$disconnectAsyncAction = AsyncAction(
    '_DeviceManagerStore.disconnect',
    context: context,
  );

  @override
  Future<void> disconnect(String serial) {
    return _$disconnectAsyncAction.run(() => super.disconnect(serial));
  }

  late final _$connectToBoxAsyncAction = AsyncAction(
    '_DeviceManagerStore.connectToBox',
    context: context,
  );

  @override
  Future<void> connectToBox() {
    return _$connectToBoxAsyncAction.run(() => super.connectToBox());
  }

  late final _$_DeviceManagerStoreActionController = ActionController(
    name: '_DeviceManagerStore',
    context: context,
  );

  @override
  void toggleDeviceSelection(String serial) {
    final _$actionInfo = _$_DeviceManagerStoreActionController.startAction(
      name: '_DeviceManagerStore.toggleDeviceSelection',
    );
    try {
      return super.toggleDeviceSelection(serial);
    } finally {
      _$_DeviceManagerStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleBroadcasting() {
    final _$actionInfo = _$_DeviceManagerStoreActionController.startAction(
      name: '_DeviceManagerStore.toggleBroadcasting',
    );
    try {
      return super.toggleBroadcasting();
    } finally {
      _$_DeviceManagerStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearSelection() {
    final _$actionInfo = _$_DeviceManagerStoreActionController.startAction(
      name: '_DeviceManagerStore.clearSelection',
    );
    try {
      return super.clearSelection();
    } finally {
      _$_DeviceManagerStoreActionController.endAction(_$actionInfo);
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
