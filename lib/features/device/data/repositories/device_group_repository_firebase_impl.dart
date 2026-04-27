import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/device/data/datasources/device_group_remote_data_source.dart';
import 'package:scraki/features/device/data/models/device_group_model.dart';
import 'package:scraki/features/device/domain/entities/device_group_entity.dart';
import 'package:scraki/features/device/domain/repositories/device_group_repository.dart';

@LazySingleton(as: DeviceGroupRepository)
class DeviceGroupRepositoryFirebaseImpl implements DeviceGroupRepository {
  final DeviceGroupRemoteDataSource _remoteDataSource;

  DeviceGroupRepositoryFirebaseImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, Unit>> deleteGroup(String collectionName, String groupId) async {
    try {
      await _remoteDataSource.deleteGroup(collectionName, groupId);
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to delete group from Firebase ($collectionName): $e'));
    }
  }

  @override
  Future<Either<Failure, List<DeviceGroupEntity>>> getGroups(String collectionName) async {
    // For single fetch (not stream). Usually watchGroups is preferred now.
    try {
      final stream = _remoteDataSource.watchGroups(collectionName);
      final models = await stream.first;
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ApiFailure('Failed to load groups from Firebase ($collectionName): $e'));
    }
  }

  @override
  Stream<Either<Failure, List<DeviceGroupEntity>>> watchGroups(String collectionName) {
    return _remoteDataSource
        .watchGroups(collectionName)
        .map((models) {
          try {
            final entities = models.map((m) => m.toEntity()).toList();
            return Right<Failure, List<DeviceGroupEntity>>(entities);
          } catch (e) {
            return Left<Failure, List<DeviceGroupEntity>>(
              ApiFailure('Failed to parse groups from stream: $e'),
            );
          }
        })
        .handleError((Object error) {
          return Left<Failure, List<DeviceGroupEntity>>(
            ApiFailure('Stream error: $error'),
          );
        });
  }

  @override
  Future<Either<Failure, Unit>> saveGroup(String collectionName, DeviceGroupEntity group) async {
    try {
      final model = DeviceGroupModel.fromEntity(group);
      await _remoteDataSource.saveGroup(collectionName, model);
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to save group to Firebase ($collectionName): $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateGroup(String collectionName, DeviceGroupEntity group) async {
    return saveGroup(collectionName, group);
  }

  @override
  Stream<Map<String, String>> watchNicknamesMap(String collectionName) {
    return _remoteDataSource.watchNicknamesMap(collectionName);
  }

  @override
  Future<Either<Failure, Unit>> updateNickname(
    String collectionName,
    String deviceSerial,
    String nickname,
  ) async {
    try {
      await _remoteDataSource.updateNickname(collectionName, deviceSerial, nickname);
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to update nickname in $collectionName: $e'));
    }
  }

  @override
  Stream<String?> watchDeviceMetadata(String collectionName, String type, String deviceSerial) {
    return _remoteDataSource.watchDeviceMetadata(collectionName, type, deviceSerial);
  }

  @override
  Future<Either<Failure, Unit>> updateDeviceMetadata(
    String collectionName,
    String type,
    String deviceSerial,
    String value,
  ) async {
    try {
      await _remoteDataSource.updateDeviceMetadata(collectionName, type, deviceSerial, value);
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to update $type for $deviceSerial in $collectionName: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeDeviceMetadata(
    String collectionName,
    String type,
    String deviceSerial,
  ) async {
    try {
      await _remoteDataSource.removeDeviceMetadata(collectionName, type, deviceSerial);
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to remove $type for $deviceSerial in $collectionName: $e'));
    }
  }
}
