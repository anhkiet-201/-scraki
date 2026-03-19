import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/features/device/domain/repositories/i_device_nickname_repository.dart';
import 'package:scraki/features/settings/presentation/stores/settings_store.dart';

part 'device_nickname_store.g.dart';

@singleton
class DeviceNicknameStore = _DeviceNicknameStore with _$DeviceNicknameStore;

abstract class _DeviceNicknameStore with Store {
  final IDeviceNicknameRepository _repository;
  final SettingsStore _settingsStore;

  _DeviceNicknameStore(this._repository, this._settingsStore) {
    // Tự động khởi động stream và lắng nghe sự thay đổi của collection
    _setupCollectionListener();
  }

  @observable
  ObservableMap<String, String> nicknames = ObservableMap<String, String>();

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  StreamSubscription<dynamic>? _nicknameSubscription;
  ReactionDisposer? _collectionDisposer;

  void _setupCollectionListener() {
    // Lắng nghe khi collection thay đổi trong Settings
    _collectionDisposer = reaction(
      (_) => _settingsStore.deviceGroupCollection,
      (_) => _startWatchingNicknames(),
      fireImmediately: true,
    );
  }

  @action
  Future<void> _startWatchingNicknames() async {
    isLoading = true;
    await _nicknameSubscription?.cancel();
    
    _nicknameSubscription = _repository.watchNicknames().listen(
      (either) {
        either.fold(
          (failure) => errorMessage = failure.message,
          (entity) {
            runInAction(() {
              nicknames.clear();
              nicknames.addAll(entity.nicknames);
              isLoading = false;
            });
          },
        );
      },
    );
  }

  @action
  Future<void> saveNickname(String deviceSerial, String nickname) async {
    final result = await _repository.saveNickname(deviceSerial, nickname);
    result.fold(
      (failure) => errorMessage = failure.message,
      (_) {
        // Optimistic update
        if (nickname.isEmpty) {
          nicknames.remove(deviceSerial);
        } else {
          nicknames[deviceSerial] = nickname;
        }
      },
    );
  }

  String getNickname(String deviceSerial, String defaultName) {
    return nicknames[deviceSerial] ?? defaultName;
  }

  void dispose() {
    _nicknameSubscription?.cancel();
    _collectionDisposer?.call();
  }
}
