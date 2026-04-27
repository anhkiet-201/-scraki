// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_group_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$DeviceGroupStore on _DeviceGroupStore, Store {
  Computed<DeviceGroupEntity?>? _$selectedGroupComputed;

  @override
  DeviceGroupEntity? get selectedGroup =>
      (_$selectedGroupComputed ??= Computed<DeviceGroupEntity?>(
        () => super.selectedGroup,
        name: '_DeviceGroupStore.selectedGroup',
      )).value;
  Computed<Set<String>>? _$visibleSerialsComputed;

  @override
  Set<String> get visibleSerials =>
      (_$visibleSerialsComputed ??= Computed<Set<String>>(
        () => super.visibleSerials,
        name: '_DeviceGroupStore.visibleSerials',
      )).value;

  late final _$groupsAtom = Atom(
    name: '_DeviceGroupStore.groups',
    context: context,
  );

  @override
  ObservableList<DeviceGroupEntity> get groups {
    _$groupsAtom.reportRead();
    return super.groups;
  }

  @override
  set groups(ObservableList<DeviceGroupEntity> value) {
    _$groupsAtom.reportWrite(value, super.groups, () {
      super.groups = value;
    });
  }

  late final _$allEmailsAtom = Atom(
    name: '_DeviceGroupStore.allEmails',
    context: context,
  );

  @override
  ObservableMap<String, String> get allEmails {
    _$allEmailsAtom.reportRead();
    return super.allEmails;
  }

  @override
  set allEmails(ObservableMap<String, String> value) {
    _$allEmailsAtom.reportWrite(value, super.allEmails, () {
      super.allEmails = value;
    });
  }

  late final _$allNicknamesAtom = Atom(
    name: '_DeviceGroupStore.allNicknames',
    context: context,
  );

  @override
  ObservableMap<String, String> get allNicknames {
    _$allNicknamesAtom.reportRead();
    return super.allNicknames;
  }

  @override
  set allNicknames(ObservableMap<String, String> value) {
    _$allNicknamesAtom.reportWrite(value, super.allNicknames, () {
      super.allNicknames = value;
    });
  }

  late final _$selectedGroupIdAtom = Atom(
    name: '_DeviceGroupStore.selectedGroupId',
    context: context,
  );

  @override
  String? get selectedGroupId {
    _$selectedGroupIdAtom.reportRead();
    return super.selectedGroupId;
  }

  @override
  set selectedGroupId(String? value) {
    _$selectedGroupIdAtom.reportWrite(value, super.selectedGroupId, () {
      super.selectedGroupId = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_DeviceGroupStore.errorMessage',
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

  late final _$createGroupAsyncAction = AsyncAction(
    '_DeviceGroupStore.createGroup',
    context: context,
  );

  @override
  Future<void> createGroup(String name) {
    return _$createGroupAsyncAction.run(() => super.createGroup(name));
  }

  late final _$deleteGroupAsyncAction = AsyncAction(
    '_DeviceGroupStore.deleteGroup',
    context: context,
  );

  @override
  Future<void> deleteGroup(String groupId) {
    return _$deleteGroupAsyncAction.run(() => super.deleteGroup(groupId));
  }

  late final _$addDeviceToGroupAsyncAction = AsyncAction(
    '_DeviceGroupStore.addDeviceToGroup',
    context: context,
  );

  @override
  Future<void> addDeviceToGroup(String groupId, String deviceSerial) {
    return _$addDeviceToGroupAsyncAction.run(
      () => super.addDeviceToGroup(groupId, deviceSerial),
    );
  }

  late final _$removeDeviceFromGroupAsyncAction = AsyncAction(
    '_DeviceGroupStore.removeDeviceFromGroup',
    context: context,
  );

  @override
  Future<void> removeDeviceFromGroup(String groupId, String deviceSerial) {
    return _$removeDeviceFromGroupAsyncAction.run(
      () => super.removeDeviceFromGroup(groupId, deviceSerial),
    );
  }

  late final _$saveNicknameForDeviceAsyncAction = AsyncAction(
    '_DeviceGroupStore.saveNicknameForDevice',
    context: context,
  );

  @override
  Future<void> saveNicknameForDevice(String deviceSerial, String nickname) {
    return _$saveNicknameForDeviceAsyncAction.run(
      () => super.saveNicknameForDevice(deviceSerial, nickname),
    );
  }

  late final _$saveEmailForDeviceAsyncAction = AsyncAction(
    '_DeviceGroupStore.saveEmailForDevice',
    context: context,
  );

  @override
  Future<void> saveEmailForDevice(String deviceSerial, String email) {
    return _$saveEmailForDeviceAsyncAction.run(
      () => super.saveEmailForDevice(deviceSerial, email),
    );
  }

  late final _$_DeviceGroupStoreActionController = ActionController(
    name: '_DeviceGroupStore',
    context: context,
  );

  @override
  void listenToGroups() {
    final _$actionInfo = _$_DeviceGroupStoreActionController.startAction(
      name: '_DeviceGroupStore.listenToGroups',
    );
    try {
      return super.listenToGroups();
    } finally {
      _$_DeviceGroupStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _syncMetadataSubscriptions() {
    final _$actionInfo = _$_DeviceGroupStoreActionController.startAction(
      name: '_DeviceGroupStore._syncMetadataSubscriptions',
    );
    try {
      return super._syncMetadataSubscriptions();
    } finally {
      _$_DeviceGroupStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _updateGroups(List<DeviceGroupEntity> list) {
    final _$actionInfo = _$_DeviceGroupStoreActionController.startAction(
      name: '_DeviceGroupStore._updateGroups',
    );
    try {
      return super._updateGroups(list);
    } finally {
      _$_DeviceGroupStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectGroup(String? groupId) {
    final _$actionInfo = _$_DeviceGroupStoreActionController.startAction(
      name: '_DeviceGroupStore.selectGroup',
    );
    try {
      return super.selectGroup(groupId);
    } finally {
      _$_DeviceGroupStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
groups: ${groups},
allEmails: ${allEmails},
allNicknames: ${allNicknames},
selectedGroupId: ${selectedGroupId},
errorMessage: ${errorMessage},
selectedGroup: ${selectedGroup},
visibleSerials: ${visibleSerials}
    ''';
  }
}
