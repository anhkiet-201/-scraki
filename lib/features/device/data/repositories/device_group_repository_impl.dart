import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/device/data/models/device_group_model.dart';
import 'package:scraki/features/device/domain/entities/device_group_entity.dart';
import 'package:scraki/features/device/domain/repositories/device_group_repository.dart';

// Removed @LazySingleton to allow DeviceGroupRepositoryFirebaseImpl to be the main implementation
class DeviceGroupRepositoryImpl implements DeviceGroupRepository {
  static const String boxName = 'device_groups';
  bool _isInitialized = false;

  Future<Box<DeviceGroupModel>> _getBox() async {
    if (!_isInitialized) {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DeviceGroupModelAdapter());
      }
      _isInitialized = true;
    }
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<DeviceGroupModel>(boxName);
    }
    return Hive.box<DeviceGroupModel>(boxName);
  }

  @override
  Future<Either<Failure, Unit>> deleteGroup(String collectionName, String groupId) async {
    try {
      final box = await _getBox();
      await box.delete(groupId);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to delete group: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DeviceGroupEntity>>> getGroups(String collectionName) async {
    try {
      final box = await _getBox();
      final groups = box.values.map((e) => e.toEntity()).toList();
      return Right(groups);
    } catch (e) {
      return Left(CacheFailure('Failed to load groups: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveGroup(String collectionName, DeviceGroupEntity group) async {
    try {
      final box = await _getBox();
      final model = DeviceGroupModel.fromEntity(group);
      await box.put(group.id, model);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to save group: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateGroup(String collectionName, DeviceGroupEntity group) async {
    return saveGroup(collectionName, group); // Save handles update if ID exists
  }

  @override
  Stream<Map<String, String>> watchNicknamesMap(String collectionName) async* {
    final box = await Hive.openBox<String>('nickname');
    yield box.toMap().cast<String, String>();
    
    await for (final _ in box.watch()) {
      yield box.toMap().cast<String, String>();
    }
  }

  @override
  Future<Either<Failure, Unit>> updateNickname(String collectionName, String deviceSerial, String nickname) async {
    try {
      final box = await Hive.openBox<String>('nickname');
      if (nickname.isEmpty) {
        await box.delete(deviceSerial);
      } else {
        await box.put(deviceSerial, nickname);
      }
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to update nickname: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<DeviceGroupEntity>>> watchGroups(String collectionName) async* {
    yield await getGroups(collectionName);
  }

  @override
  Stream<String?> watchDeviceMetadata(String collectionName, String type, String deviceSerial) async* {
    final box = await Hive.openBox<String>(type);
    yield box.get(deviceSerial);
    
    await for (final event in box.watch(key: deviceSerial)) {
      yield event.value as String?;
    }
  }

  @override
  Future<Either<Failure, Unit>> updateDeviceMetadata(
    String collectionName,
    String type,
    String deviceSerial,
    String value,
  ) async {
    try {
      final box = await Hive.openBox<String>(type);
      await box.put(deviceSerial, value);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to update metadata: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeDeviceMetadata(String collectionName, String type, String deviceSerial) async {
    try {
      final box = await Hive.openBox<String>(type);
      await box.delete(deviceSerial);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to remove metadata: $e'));
    }
  }
}
