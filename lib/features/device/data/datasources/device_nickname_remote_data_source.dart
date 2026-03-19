import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/config/settings_config_provider.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/device/data/models/device_nickname_model.dart';

abstract class IDeviceNicknameRemoteDataSource {
  Stream<Either<Failure, DeviceNicknameModel>> watchNicknames();
  Future<Either<Failure, Unit>> saveNickname(String deviceSerial, String nickname);
}

@LazySingleton(as: IDeviceNicknameRemoteDataSource)
class DeviceNicknameRemoteDataSourceImpl implements IDeviceNicknameRemoteDataSource {
  final FirebaseFirestore _firestore;
  final SettingsConfigProvider _configProvider;
  static const String _collectionName = 'app_configs';

  DeviceNicknameRemoteDataSourceImpl(this._configProvider)
      : _firestore = FirebaseFirestore.instance;

  String get _documentId => 'nicknames_${_configProvider.deviceGroupCollection}';

  DocumentReference get _document => 
      _firestore.collection(_collectionName).doc(_documentId);

  @override
  Stream<Either<Failure, DeviceNicknameModel>> watchNicknames() {
    return _document.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return Right(DeviceNicknameModel(nicknames: {}));
      }
      try {
        final data = snapshot.data() as Map<String, dynamic>;
        return Right(DeviceNicknameModel.fromJson(data));
      } catch (e) {
        return Left(ApiFailure('Lỗi parse device nicknames: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, Unit>> saveNickname(
    String deviceSerial,
    String nickname,
  ) async {
    try {
      final safeKey = deviceSerial
          .replaceAll('.', '_dot_')
          .replaceAll(':', '_colon_');
          
      final Map<String, dynamic> updateData = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (nickname.isEmpty) {
        // Delete field using dot notation for nested map update
        updateData['nicknames.$safeKey'] = FieldValue.delete();
      } else {
        updateData['nicknames.$safeKey'] = nickname;
      }

      await _document.update(updateData);
      return const Right(unit);
    } catch (e) {
      // If document doesn't exist, we might need to use set with merge: true
      // However, we can also just use set if we want to be safe
      try {
        final safeKey = deviceSerial
            .replaceAll('.', '_dot_')
            .replaceAll(':', '_colon_');
        await _document.set({
          'nicknames': {
            safeKey: nickname.isEmpty ? FieldValue.delete() : nickname,
          },
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return const Right(unit);
      } catch (e2) {
        return Left(ApiFailure('Lỗi lưu nickname thiết bị: $e2'));
      }
    }
  }
}
