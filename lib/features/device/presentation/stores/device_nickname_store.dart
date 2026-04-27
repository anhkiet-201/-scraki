import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/features/device/presentation/stores/device_group_store.dart';

part 'device_nickname_store.g.dart';

@singleton
// ignore: library_private_types_in_public_api
class DeviceNicknameStore = _DeviceNicknameStore with _$DeviceNicknameStore;

abstract class _DeviceNicknameStore with Store {
  final DeviceGroupStore _deviceGroupStore;

  _DeviceNicknameStore(
    this._deviceGroupStore,
  ) {
    // DeviceGroupStore handles syncing
  }

  @computed
  ObservableMap<String, String> get nicknames => _deviceGroupStore.allNicknames;

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  StreamSubscription<dynamic>? _nicknameSubscription;
  ReactionDisposer? _collectionDisposer;

  @action
  Future<void> saveNickname(String deviceSerial, String nickname) async {
    await _deviceGroupStore.saveNicknameForDevice(deviceSerial, nickname);
  }

  String getNickname(String deviceSerial, String defaultName) {
    return _deviceGroupStore.getNicknameForDevice(deviceSerial) ?? defaultName;
  }

  void dispose() {
    _nicknameSubscription?.cancel();
    _collectionDisposer?.call();
  }
}
