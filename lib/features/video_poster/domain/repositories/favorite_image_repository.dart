import 'package:scraki/features/video_poster/domain/entities/favorite_image.dart';

abstract class FavoriteImageRepository {
  Future<List<FavoriteImage>> getFavorites();
  Future<void> addFavorite(FavoriteImage image);
  Future<void> removeFavorite(String id);
}
