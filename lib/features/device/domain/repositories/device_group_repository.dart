import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/device/domain/entities/device_group_entity.dart';

abstract class DeviceGroupRepository {
  Future<Either<Failure, List<DeviceGroupEntity>>> getGroups(String collectionName);
  Stream<Either<Failure, List<DeviceGroupEntity>>> watchGroups(String collectionName);
  Future<Either<Failure, Unit>> saveGroup(String collectionName, DeviceGroupEntity group);
  Future<Either<Failure, Unit>> deleteGroup(String collectionName, String groupId);
  Future<Either<Failure, Unit>> updateGroup(String collectionName, DeviceGroupEntity group);

  // Nickname Methods
  Stream<Map<String, String>> watchNicknamesMap(String collectionName);
  Future<Either<Failure, Unit>> updateNickname(String collectionName, String deviceSerial, String nickname);

  // Device Metadata Methods (e.g. Email)
  Stream<String?> watchDeviceMetadata(String collectionName, String type, String deviceSerial);
  Future<Either<Failure, Unit>> updateDeviceMetadata(String collectionName, String type, String deviceSerial, String value);
  Future<Either<Failure, Unit>> removeDeviceMetadata(String collectionName, String type, String deviceSerial);
}
