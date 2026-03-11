import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/utils/logger.dart';
import 'package:scraki/features/video_poster/data/models/favorite_image_model.dart';

abstract class FavoriteImageRemoteDataSource {
  Future<List<FavoriteImageModel>> getFavorites();
  Future<void> addFavorite(FavoriteImageModel model);
  Future<void> removeFavorite(String id);
}

@LazySingleton(as: FavoriteImageRemoteDataSource)
class FavoriteImageRemoteDataSourceImpl
    implements FavoriteImageRemoteDataSource {
  CollectionReference get _collection =>
      FirebaseFirestore.instance.collection('favorite_images');

  @override
  Future<List<FavoriteImageModel>> getFavorites() async {
    try {
      final snapshot = await _collection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Nếu id chưa lưu trong map
        return FavoriteImageModel.fromJson(data);
      }).toList();
    } catch (e) {
      logger.e('[Firestore] getFavorites failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> addFavorite(FavoriteImageModel model) async {
    try {
      await _collection.doc(model.id).set(model.toJson());
      logger.i('[Firestore] Added favorite ${model.id}');
    } catch (e) {
      logger.e('[Firestore] addFavorite failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFavorite(String id) async {
    try {
      await _collection.doc(id).delete();
      logger.i('[Firestore] Removed favorite $id');
    } catch (e) {
      logger.e('[Firestore] removeFavorite failed: $e');
      rethrow;
    }
  }
}
