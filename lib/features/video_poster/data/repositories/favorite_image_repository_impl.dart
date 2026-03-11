import 'package:injectable/injectable.dart';
import 'package:scraki/features/video_poster/data/datasources/favorite_image_remote_data_source.dart';
import 'package:scraki/features/video_poster/data/models/favorite_image_model.dart';
import 'package:scraki/features/video_poster/domain/entities/favorite_image.dart';
import 'package:scraki/features/video_poster/domain/repositories/favorite_image_repository.dart';

@LazySingleton(as: FavoriteImageRepository)
class FavoriteImageRepositoryImpl implements FavoriteImageRepository {
  final FavoriteImageRemoteDataSource _remoteDataSource;

  FavoriteImageRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<FavoriteImage>> getFavorites() async {
    final models = await _remoteDataSource.getFavorites();
    return models; // Models extend FavoriteImage
  }

  @override
  Future<void> addFavorite(FavoriteImage image) async {
    final model = FavoriteImageModel.fromEntity(image);
    await _remoteDataSource.addFavorite(model);
  }

  @override
  Future<void> removeFavorite(String id) async {
    await _remoteDataSource.removeFavorite(id);
  }
}
