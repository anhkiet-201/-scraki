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

part 'device_group_store.g.dart';

@lazySingleton
// ignore: library_private_types_in_public_api
class DeviceGroupStore = _DeviceGroupStore with _$DeviceGroupStore;

abstract class _DeviceGroupStore with Store {
  final DeviceGroupRepository _repository;
  final DeviceManagerStore _deviceManagerStore;
  final DashboardStore _dashboardStore;

  _DeviceGroupStore(
    this._repository,
    this._deviceManagerStore,
    this._dashboardStore,
  );

  @observable
  ObservableList<DeviceGroupEntity> groups =
      ObservableList<DeviceGroupEntity>();

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
        final matchesDevice =
            d.serial.toLowerCase().contains(query) ||
            d.modelName.toLowerCase().contains(query);
        final matchesGroup = serialsInMatchingGroups.contains(d.serial);
        return matchesDevice || matchesGroup;
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
  bool _isListeningToGroups = false;

  @action
  void listenToGroups() {
    if (_isListeningToGroups) return;
    _isListeningToGroups = true;

    _groupSubscription?.cancel();
    _groupSubscription = _repository.watchGroups().listen((result) {
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
          // Wrap in action to mutate observable
          _updateGroups(list);
        },
      );
    });
  }

  @action
  void _updateGroups(List<DeviceGroupEntity> list) {
    groups.clear();
    groups.addAll(list);
  }

  void dispose() {
    _groupSubscription?.cancel();
  }

  @action
  Future<void> createGroup(String name) async {
    // Generate random color
    final colorValue =
        (0xFF000000 + (DateTime.now().microsecondsSinceEpoch & 0xFFFFFF))
            .toInt() |
        0xFF000000; // Ensure alpha is FF

    final newGroup = DeviceGroupEntity.create(
      name: name,
      colorValue: colorValue,
    );

    final result = await _repository.saveGroup(newGroup);
    result.fold((failure) => errorMessage = failure.message, (_) {
      // Stream updates ui automatically
      logger.i('[DeviceGroupStore] Created group: $name (Pending sync)');
    });
  }

  @action
  Future<void> deleteGroup(String groupId) async {
    final result = await _repository.deleteGroup(groupId);
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

    final result = await _repository.updateGroup(updatedGroup);
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

    final result = await _repository.updateGroup(updatedGroup);
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
    for (final group in groups) {
      if (group.deviceSerials.contains(deviceSerial)) {
        return group.deviceEmails[deviceSerial];
      }
    }
    return null;
  }

  @action
  Future<void> saveEmailForDevice(String deviceSerial, String email) async {
    logger.i(
      '[DeviceGroupStore] Trying to save email "$email" for device "$deviceSerial". Total groups: ${groups.length}',
    );
    bool foundDeviceInAnyGroup = false;

    for (final group in groups) {
      if (group.deviceSerials.contains(deviceSerial)) {
        foundDeviceInAnyGroup = true;
        logger.i(
          '[DeviceGroupStore] Found device in group: ${group.name}. Current email: ${group.deviceEmails[deviceSerial]}',
        );

        if (group.deviceEmails[deviceSerial] != email) {
          logger.i(
            '[DeviceGroupStore] Email changed. Proceeding to update group in Firebase...',
          );
          final newEmails = Map<String, String>.from(group.deviceEmails);
          newEmails[deviceSerial] = email;
          final updatedGroup = group.copyWith(deviceEmails: newEmails);
          final result = await _repository.updateGroup(updatedGroup);
          result.fold(
            (failure) {
              logger.e('[DeviceGroupStore] Lỗi lưu email: ${failure.message}');
              errorMessage = failure.message;
            },
            (_) {
              logger.i(
                '[DeviceGroupStore] Saved email $email for device $deviceSerial to group ${group.name}',
              );
              final index = groups.indexWhere((g) => g.id == group.id);
              if (index != -1) groups[index] = updatedGroup;
            },
          );
        } else {
          logger.i(
            '[DeviceGroupStore] Email is already assigned to this device in Firebase. Skipping update.',
          );
        }
        break; // Update the first matching group only
      }
    }

    if (!foundDeviceInAnyGroup) {
      logger.w(
        '[DeviceGroupStore] WARNING: Device $deviceSerial is NOT in any group. Cannot save email!',
      );
    }
  }
}
