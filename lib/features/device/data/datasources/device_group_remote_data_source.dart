import 'package:cloud_firestore/cloud_firestore.dart';
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
  final CollectionReference _collection;

  DeviceGroupRemoteDataSourceImpl()
    : _collection = FirebaseFirestore.instance.collection('device_groups');

  @override
  Stream<List<DeviceGroupModel>> watchGroups() {
    logger.i('[Firestore] Bắt đầu theo dõi bảng device_groups...');

    return _collection
        .snapshots()
        .map((snapshot) {
          final groups = <DeviceGroupModel>[];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              groups.add(DeviceGroupModel.fromJson(data));
            } catch (e) {
              logger.e('[Firestore] Error parsing group ${doc.id}: $e');
            }
          }
          return groups;
        })
        .handleError((Object error) {
          logger.e('[Firestore] Lỗi stream watchGroups: $error');
        });
  }

  @override
  Future<void> saveGroup(DeviceGroupModel group) async {
    try {
      await _collection.doc(group.id).set(group.toJson());
      logger.i('[Firestore] Saved group ${group.id}');
    } catch (e) {
      logger.e('[Firestore] Save group failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    try {
      await _collection.doc(groupId).delete();
      logger.i('[Firestore] Deleted group $groupId');
    } catch (e) {
      logger.e('[Firestore] Delete group failed: $e');
      rethrow;
    }
  }
}
