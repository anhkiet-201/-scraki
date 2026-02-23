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
  Future<Either<Failure, Unit>> deleteGroup(String groupId) async {
    try {
      await _remoteDataSource.deleteGroup(groupId);
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to delete group from Firebase: $e'));
    }
  }

  @override
  Future<Either<Failure, List<DeviceGroupEntity>>> getGroups() async {
    // For single fetch (not stream). Usually watchGroups is preferred now.
    try {
      final stream = _remoteDataSource.watchGroups();
      final models = await stream.first;
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ApiFailure('Failed to load groups from Firebase: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<DeviceGroupEntity>>> watchGroups() {
    return _remoteDataSource
        .watchGroups()
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
  Future<Either<Failure, Unit>> saveGroup(DeviceGroupEntity group) async {
    try {
      final model = DeviceGroupModel.fromEntity(group);
      await _remoteDataSource.saveGroup(model);
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure('Failed to save group to Firebase: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateGroup(DeviceGroupEntity group) async {
    return saveGroup(group);
  }
}
