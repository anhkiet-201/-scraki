import 'package:firebase_database/firebase_database.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/data/models/device_group_model.dart';

abstract class DeviceGroupRemoteDataSource {
  Stream<List<DeviceGroupModel>> watchGroups();
  Future<void> saveGroup(DeviceGroupModel group);
  Future<void> deleteGroup(String groupId);
}

@LazySingleton(as: DeviceGroupRemoteDataSource)
class DeviceGroupRemoteDataSourceImpl implements DeviceGroupRemoteDataSource {
  final DatabaseReference _dbRef;

  DeviceGroupRemoteDataSourceImpl()
    : _dbRef = FirebaseDatabase.instance.ref().child('device_groups') {
    // Enable offline persistence for RTDB by default
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(
        10000000,
      ); // 10MB cache
    } catch (e) {
      logger.w(
        '[FirebaseRTDB] setPersistenceEnabled error (often expected if already initialized): $e',
      );
    }
  }

  @override
  Stream<List<DeviceGroupModel>> watchGroups() {
    return _dbRef.onValue.map((event) {
      final groups = <DeviceGroupModel>[];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            // Need to convert Map<dynamic, dynamic> to Map<String, dynamic>
            final mapData = Map<String, dynamic>.from(value as Map);
            // Assuming DeviceGroupModel has a fromJson factory.
            // We might need to write a manual parser if mapping is different.
            groups.add(DeviceGroupModel.fromJson(mapData));
          } catch (e) {
            logger.e('[FirebaseRTDB] Error parsing group $key: $e');
          }
        });
      }
      return groups;
    });
  }

  @override
  Future<void> saveGroup(DeviceGroupModel group) async {
    // Map serialization to JSON before saving
    await _dbRef.child(group.id).set(group.toJson());
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _dbRef.child(groupId).remove();
  }
}
