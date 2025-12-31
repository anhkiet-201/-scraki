import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../entities/device_entity.dart';

abstract class DeviceRepository {
  /// Retrieves a list of connected devices.
  Future<Either<Failure, List<DeviceEntity>>> getConnectedDevices();

  /// Connects to a device via TCP/IP.
  Future<Either<Failure, Unit>> connectTcp(String ip, int port);

  /// Disconnects a device.
  Future<Either<Failure, Unit>> disconnectDevice(String serial);
}
