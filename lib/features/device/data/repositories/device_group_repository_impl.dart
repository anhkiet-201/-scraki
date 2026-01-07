import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/device/data/models/device_group_model.dart';
import 'package:scraki/features/device/domain/entities/device_group_entity.dart';
import 'package:scraki/features/device/domain/repositories/device_group_repository.dart';

@LazySingleton(as: DeviceGroupRepository)
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
  Future<Either<Failure, Unit>> deleteGroup(String groupId) async {
    try {
      final box = await _getBox();
      await box.delete(groupId);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to delete group: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DeviceGroupEntity>>> getGroups() async {
    try {
      final box = await _getBox();
      final groups = box.values.map((e) => e.toEntity()).toList();
      return Right(groups);
    } catch (e) {
      return Left(CacheFailure('Failed to load groups: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveGroup(DeviceGroupEntity group) async {
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
  Future<Either<Failure, Unit>> updateGroup(DeviceGroupEntity group) async {
    return saveGroup(group); // Save handles update if ID exists
  }
}
