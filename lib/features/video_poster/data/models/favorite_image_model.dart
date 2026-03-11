import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scraki/features/video_poster/domain/entities/favorite_image.dart';

class FavoriteImageModel extends FavoriteImage {
  const FavoriteImageModel({
    required super.id,
    required super.url,
    super.isGif = false,
    required super.createdAt,
  });

  factory FavoriteImageModel.fromJson(Map<String, dynamic> json) {
    return FavoriteImageModel(
      id: json['id'] as String,
      url: json['url'] as String,
      isGif: json['isGif'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'isGif': isGif,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FavoriteImageModel.fromEntity(FavoriteImage entity) {
    return FavoriteImageModel(
      id: entity.id,
      url: entity.url,
      isGif: entity.isGif,
      createdAt: entity.createdAt,
    );
  }
}
