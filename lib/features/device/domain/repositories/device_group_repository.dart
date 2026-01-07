import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/device/domain/entities/device_group_entity.dart';

abstract class DeviceGroupRepository {
  Future<Either<Failure, List<DeviceGroupEntity>>> getGroups();
  Future<Either<Failure, Unit>> saveGroup(DeviceGroupEntity group);
  Future<Either<Failure, Unit>> deleteGroup(String groupId);
  Future<Either<Failure, Unit>> updateGroup(DeviceGroupEntity group);
}
