import 'package:equatable/equatable.dart';

class FavoriteImage extends Equatable {
  final String id;
  final String url;
  final bool isGif;
  final DateTime createdAt;

  const FavoriteImage({
    required this.id,
    required this.url,
    this.isGif = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, url, isGif, createdAt];
}
