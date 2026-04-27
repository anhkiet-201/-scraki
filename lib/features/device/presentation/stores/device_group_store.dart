import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/core/stores/device_manager_store.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/dashboard/presentation/stores/dashboard_store.dart';
import 'package:scraki/features/device/domain/entities/device_group_entity.dart';
import 'package:scraki/features/device/domain/repositories/device_group_repository.dart';
import 'package:scraki/features/settings/presentation/stores/settings_store.dart';

part 'device_group_store.g.dart';

@lazySingleton
// ignore: library_private_types_in_public_api
class DeviceGroupStore = _DeviceGroupStore with _$DeviceGroupStore;

abstract class _DeviceGroupStore with Store {
  final DeviceGroupRepository _repository;
  final DeviceManagerStore _deviceManagerStore;
  final DashboardStore _dashboardStore;
  final SettingsStore _settingsStore;

  _DeviceGroupStore(
    this._repository,
    this._deviceManagerStore,
    this._dashboardStore,
    this._settingsStore,
  ) {
    // Tự động re-subscribe khi collection thay đổi trong Settings
    reaction((_) => _settingsStore.deviceGroupCollection, (collection) {
      logger.i(
        '[DeviceGroupStore] Collection changed to "$collection". Re-initializing streams...',
      );
      _isListeningToGroups = false;
      listenToGroups();
    });
  }

  @observable
  ObservableList<DeviceGroupEntity> groups =
      ObservableList<DeviceGroupEntity>();

  @observable
  ObservableMap<String, String> allEmails = ObservableMap<String, String>();

  @observable
  ObservableMap<String, String> allNicknames = ObservableMap<String, String>();

  @observable
  String? selectedGroupId;

  @observable
  String? errorMessage;

  @computed
  DeviceGroupEntity? get selectedGroup => selectedGroupId == null
      ? null
      : groups.firstWhere(
          (g) => g.id == selectedGroupId,
          orElse: () => groups.first,
        );

  @computed
  Set<String> get visibleSerials {
    final allDevices = _deviceManagerStore.devices;
    var devices = allDevices.toList();

    // 1. Filter by Sidebar Selection
    if (selectedGroupId != null) {
      final group = groups.where((g) => g.id == selectedGroupId).firstOrNull;

      if (group != null) {
        devices = devices
            .where((d) => group.deviceSerials.contains(d.serial))
            .toList();
      } else {
        // Group selected but not found
        // Return empty set implies hide all? Or behave like no selection?
        // UI expects filtered list, so empty.
        return {};
      }
    }

    // 2. Filter by Search Query
    final query = _dashboardStore.searchQuery.toLowerCase();
    if (query.isNotEmpty) {
      final matchingGroups = groups
          .where((g) => g.name.toLowerCase().contains(query))
          .toList();
      final serialsInMatchingGroups = matchingGroups
          .expand((g) => g.deviceSerials)
          .toSet();

      devices = devices.where((d) {
        final matchesDevice = d.serial.toLowerCase().contains(query) ||
            d.modelName.toLowerCase().contains(query);

        // Check if nickname matches
        final nickname = getNicknameForDevice(d.serial) ?? d.modelName;
        final matchesNickname = nickname.toLowerCase().contains(query);

        final matchesGroup = serialsInMatchingGroups.contains(d.serial);

        return matchesDevice || matchesNickname || matchesGroup;
      }).toList();
    }

    // If no filters active, return all serials
    if (selectedGroupId == null && query.isEmpty) {
      return allDevices.map((d) => d.serial).toSet();
    }

    return devices.map((d) => d.serial).toSet();
  }

  StreamSubscription<Either<Failure, List<DeviceGroupEntity>>>?
  _groupSubscription;
  
  // Quản lý các subscription
  final Map<String, StreamSubscription<String?>> _emailSubscriptions = {};
  StreamSubscription<Map<String, String>>? _nicknameSubscription;
  
  bool _isListeningToGroups = false;

  @action
  void listenToGroups() {
    if (_isListeningToGroups) return;
    _isListeningToGroups = true;

    // Clear old data when switching collections
    runInAction(() {
      groups.clear();
      allEmails.clear();
      allNicknames.clear();
    });

    _groupSubscription?.cancel();
    _nicknameSubscription?.cancel();

    _nicknameSubscription = _repository
        .watchNicknamesMap(_settingsStore.deviceGroupCollection)
        .listen((map) {
      runInAction(() {
        allNicknames.clear();
        allNicknames.addAll(map);
      });
    });

    _groupSubscription = _repository.watchGroups(_settingsStore.deviceGroupCollection).listen((result) {
      result.fold(
        (failure) {
          errorMessage = failure.message;
          logger.e(
            '[DeviceGroupStore] Failed to stream groups: ${failure.message}',
          );
        },
        (list) {
          logger.i(
            '[DeviceGroupStore] Received ${list.length} groups from Firebase',
          );
          _updateGroups(list);
          
          // Sau khi có danh sách group, hãy đảm bảo metadata được load cho các thiết bị trong group
          _syncMetadataSubscriptions();
        },
      );
    });
  }

  /// Quản lý việc subscribe/unsubscribe metadata cho các thiết bị cần thiết
  @action
  void _syncMetadataSubscriptions() {
    final allSerialsInGroups = groups.expand((g) => g.deviceSerials).toSet();
    
    // Tạm thời: Load metadata cho tất cả thiết bị có trong group
    // (Trong tương lai có thể tối ưu chỉ load thiết bị đang hiển thị)
    for (final serial in allSerialsInGroups) {
      _subscribeToDeviceMetadata(serial);
    }
  }

  void _subscribeToDeviceMetadata(String serial) {
    if (!_emailSubscriptions.containsKey(serial)) {
      _emailSubscriptions[serial] = _repository
          .watchDeviceMetadata(_settingsStore.deviceGroupCollection, 'email', serial)
          .listen((value) {
            runInAction(() => allEmails[serial] = value ?? '');
          });
    }
  }

  @action
  void _updateGroups(List<DeviceGroupEntity> list) {
    groups.clear();
    groups.addAll(list);
  }

  void dispose() {
    _groupSubscription?.cancel();
    _nicknameSubscription?.cancel();
    for (var sub in _emailSubscriptions.values) {
      sub.cancel();
    }
    _emailSubscriptions.clear();
  }

  @action
  Future<void> createGroup(String name) async {
    const distinctColors = [
      0xFFF44336, // Red
      0xFF2196F3, // Blue
      0xFF4CAF50, // Green
      0xFFFF9800, // Orange
      0xFF9C27B0, // Purple
      0xFF009688, // Teal
      0xFEFFC107, // Amber (modified to avoid white-ish yellow on light theme)
      0xFF00BCD4, // Cyan
      0xFFE91E63, // Pink
      0xFF3F51B5, // Indigo
      0xFF795548, // Brown
      0xFFFF5722, // Deep Orange
    ];

    // Find a color that isn't currently used by any group
    final usedColors = groups.map((g) => g.colorValue).toSet();
    int colorValue = distinctColors.first;
    bool foundUnique = false;

    for (final color in distinctColors) {
      if (!usedColors.contains(color)) {
        colorValue = color;
        foundUnique = true;
        break;
      }
    }

    // Fallback if all distinct colors are used
    if (!foundUnique) {
      final colorIndex = groups.length % distinctColors.length;
      colorValue = distinctColors[colorIndex];
    }

    final newGroup = DeviceGroupEntity.create(
      name: name,
      colorValue: colorValue,
    );

    final result = await _repository.saveGroup(_settingsStore.deviceGroupCollection, newGroup);
    result.fold((failure) => errorMessage = failure.message, (_) {
      // Stream updates ui automatically
      logger.i('[DeviceGroupStore] Created group: $name (Pending sync)');
    });
  }

  @action
  Future<void> deleteGroup(String groupId) async {
    final result = await _repository.deleteGroup(_settingsStore.deviceGroupCollection, groupId);
    result.fold((failure) => errorMessage = failure.message, (_) {
      // Stream updates ui automatically
      if (selectedGroupId == groupId) {
        selectedGroupId = null;
      }
    });
  }

  @action
  Future<void> addDeviceToGroup(String groupId, String deviceSerial) async {
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;

    final group = groups[index];
    if (group.deviceSerials.contains(deviceSerial)) return;

    final updatedGroup = group.copyWith(
      deviceSerials: [...group.deviceSerials, deviceSerial],
    );

    final result = await _repository.updateGroup(_settingsStore.deviceGroupCollection, updatedGroup);
    result.fold((failure) => errorMessage = failure.message, (_) {
      groups[index] = updatedGroup;
    });
  }

  @action
  Future<void> removeDeviceFromGroup(
    String groupId,
    String deviceSerial,
  ) async {
    final index = groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;

    final group = groups[index];
    if (!group.deviceSerials.contains(deviceSerial)) return;

    final updatedGroup = group.copyWith(
      deviceSerials: group.deviceSerials
          .where((s) => s != deviceSerial)
          .toList(),
    );

    final result = await _repository.updateGroup(_settingsStore.deviceGroupCollection, updatedGroup);
    result.fold((failure) => errorMessage = failure.message, (_) {
      groups[index] = updatedGroup;
    });
  }

  @action
  void selectGroup(String? groupId) {
    if (selectedGroupId == groupId) {
      selectedGroupId = null; // Toggle off
    } else {
      selectedGroupId = groupId;
    }
  }

  String? getEmailForDevice(String deviceSerial) {
    return allEmails[deviceSerial];
  }

  String? getNicknameForDevice(String deviceSerial) {
    return allNicknames[deviceSerial];
  }

  @action
  Future<void> saveNicknameForDevice(String deviceSerial, String nickname) async {
    logger.i(
      '[DeviceGroupStore] Saving nickname "$nickname" for device "$deviceSerial" to metadata map.',
    );

    final result = await _repository.updateNickname(
      _settingsStore.deviceGroupCollection,
      deviceSerial,
      nickname,
    );
    
    result.fold(
      (failure) => errorMessage = failure.message,
      (_) => logger.i('[DeviceGroupStore] Saved nickname $nickname for $deviceSerial'),
    );
  }

  @action
  Future<void> saveEmailForDevice(String deviceSerial, String email) async {
    logger.i(
      '[DeviceGroupStore] Saving email "$email" for device "$deviceSerial" to granular document.',
    );

    if (email.isEmpty) {
      final result = await _repository.removeDeviceMetadata(_settingsStore.deviceGroupCollection, 'email', deviceSerial);
      result.fold(
        (failure) => errorMessage = failure.message,
        (_) => logger.i('[DeviceGroupStore] Removed email for $deviceSerial'),
      );
    } else {
      final result = await _repository.updateDeviceMetadata(_settingsStore.deviceGroupCollection, 'email', deviceSerial, email);
      result.fold(
        (failure) => errorMessage = failure.message,
        (_) => logger.i('[DeviceGroupStore] Saved email $email for $deviceSerial'),
      );
    }
  }
}
