import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/utils/adb_output_parser.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/adb_remote_data_source.dart';

@LazySingleton(as: DeviceRepository)
class DeviceRepositoryImpl implements DeviceRepository {
  final IAdbRemoteDataSource _remoteDataSource;

  DeviceRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<DeviceEntity>>> getConnectedDevices() async {
    try {
      final output = await _remoteDataSource.getConnectedDevicesOutput();
      final devices = AdbOutputParser.parseDevices(output);
      return Right(devices);
    } on ServerException catch (e) {
      return Left(AdbFailure(e.message));
    } catch (e) {
      return Left(const AdbFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Unit>> connectTcp(String ip, int port) async {
    try {
      await _remoteDataSource.connectTcp(ip, port);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(const ConnectionFailure('Unexpected connection error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> disconnectDevice(String serial) async {
    try {
      await _remoteDataSource.disconnect(serial); // Changed method name
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(AdbFailure(e.message));
    } catch (e) {
      return Left(const AdbFailure('Unexpected error during disconnect'));
    }
  }
}
