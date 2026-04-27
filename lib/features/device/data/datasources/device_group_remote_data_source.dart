import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/device/data/models/device_group_model.dart';

abstract class DeviceGroupRemoteDataSource {
  Stream<List<DeviceGroupModel>> watchGroups(String collectionName);
  Future<void> saveGroup(String collectionName, DeviceGroupModel group);
  Future<void> deleteGroup(String collectionName, String groupId);

  // Device Metadata Methods (Granular access)
  Stream<String?> watchDeviceMetadata(String collectionName, String type, String deviceSerial);
  Future<void> updateDeviceMetadata(String collectionName, String type, String deviceSerial, String value);
  Future<void> removeDeviceMetadata(String collectionName, String type, String deviceSerial);
}

@LazySingleton(as: DeviceGroupRemoteDataSource)
class DeviceGroupRemoteDataSourceImpl implements DeviceGroupRemoteDataSource {

  DeviceGroupRemoteDataSourceImpl();

  // Helper to get base collection
  CollectionReference _getBaseCollection(String collectionName) => 
      FirebaseFirestore.instance.collection(collectionName);

  // Helper to get group sub-collection
  CollectionReference _getGroupCollection(String collectionName) => 
      _getBaseCollection(collectionName).doc('data').collection('group');

  @override
  Stream<List<DeviceGroupModel>> watchGroups(String collectionName) {
    logger.i('[Firestore] Bắt đầu theo dõi groups tại $collectionName/data/group...');

    return _getGroupCollection(collectionName)
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
  Future<void> saveGroup(String collectionName, DeviceGroupModel group) async {
    try {
      await _getGroupCollection(collectionName).doc(group.id).set(group.toJson());
      logger.i('[Firestore] Saved group ${group.id} to $collectionName/data/group');
    } catch (e) {
      logger.e('[Firestore] Save group failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteGroup(String collectionName, String groupId) async {
    try {
      await _getGroupCollection(collectionName).doc(groupId).delete();
      logger.i('[Firestore] Deleted group $groupId from $collectionName/data/group');
    } catch (e) {
      logger.e('[Firestore] Delete group failed: $e');
      rethrow;
    }
  }

  @override
  Stream<String?> watchDeviceMetadata(String collectionName, String type, String deviceSerial) {
    final safeSerial = deviceSerial.replaceAll('.', '_dot_').replaceAll(':', '_colon_');
    return _getBaseCollection(collectionName)
        .doc('data')
        .collection(type)
        .doc(safeSerial)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final data = doc.data();
          return data?['value'] as String?;
        });
  }

  @override
  Future<void> updateDeviceMetadata(String collectionName, String type, String deviceSerial, String value) async {
    final safeSerial = deviceSerial.replaceAll('.', '_dot_').replaceAll(':', '_colon_');
    try {
      await _getBaseCollection(collectionName)
          .doc('data')
          .collection(type)
          .doc(safeSerial)
          .set({
            'value': value,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      logger.i('[Firestore] Updated $type for $deviceSerial in $collectionName');
    } catch (e) {
      logger.e('[Firestore] Update $type failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeDeviceMetadata(String collectionName, String type, String deviceSerial) async {
    final safeSerial = deviceSerial.replaceAll('.', '_dot_').replaceAll(':', '_colon_');
    try {
      await _getBaseCollection(collectionName)
          .doc('data')
          .collection(type)
          .doc(safeSerial)
          .delete();
      logger.i('[Firestore] Removed $type for $deviceSerial in $collectionName');
    } catch (e) {
      logger.e('[Firestore] Remove $type failed: $e');
      rethrow;
    }
  }
}
