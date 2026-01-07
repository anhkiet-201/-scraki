import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
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

  @action
  Future<void> loadGroups() async {
    final result = await _repository.getGroups();
    result.fold(
      (failure) {
        errorMessage = failure.message;
        logger.e(
          '[DeviceGroupStore] Failed to load groups: ${failure.message}',
        );
      },
      (list) {
        groups.clear();
        groups.addAll(list);
      },
    );
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
      groups.add(newGroup);
      logger.i('[DeviceGroupStore] Created group: $name');
    });
  }

  @action
  Future<void> deleteGroup(String groupId) async {
    final result = await _repository.deleteGroup(groupId);
    result.fold((failure) => errorMessage = failure.message, (_) {
      groups.removeWhere((g) => g.id == groupId);
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
}
