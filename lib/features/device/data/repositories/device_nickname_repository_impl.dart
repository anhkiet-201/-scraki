import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/device/data/datasources/device_nickname_remote_data_source.dart';
import 'package:scraki/features/device/domain/entities/device_nickname_entity.dart';
import 'package:scraki/features/device/domain/repositories/i_device_nickname_repository.dart';

@LazySingleton(as: IDeviceNicknameRepository)
class DeviceNicknameRepositoryImpl implements IDeviceNicknameRepository {
  final IDeviceNicknameRemoteDataSource _remoteDataSource;

  DeviceNicknameRepositoryImpl(this._remoteDataSource);

  @override
  Stream<Either<Failure, DeviceNicknameEntity>> watchNicknames() {
    return _remoteDataSource.watchNicknames().map(
          (either) => either.map((model) => model.toEntity()),
        );
  }

  @override
  Future<Either<Failure, Unit>> saveNickname(String deviceSerial, String nickname) {
    return _remoteDataSource.saveNickname(deviceSerial, nickname);
  }
}
