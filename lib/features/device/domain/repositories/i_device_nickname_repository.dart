import 'package:fpdart/fpdart.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/device/domain/entities/device_nickname_entity.dart';

abstract class IDeviceNicknameRepository {
  Stream<Either<Failure, DeviceNicknameEntity>> watchNicknames();
  Future<Either<Failure, Unit>> saveNickname(String deviceSerial, String nickname);
}
