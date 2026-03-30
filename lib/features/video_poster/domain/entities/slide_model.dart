import 'package:scraki/features/video_poster/domain/entities/custom_image_overlay.dart';
import 'package:scraki/features/video_poster/domain/entities/custom_text_overlay.dart';

/// Represents a single slide in the Image Poster generation process.
/// Each slide contains its own set of text and image overlays.
class SlideModel {
  final String id;
  final String name;
  final List<CustomTextOverlay> texts;
  final List<CustomImageOverlay> images;

  const SlideModel({
    required this.id,
    required this.name,
    this.texts = const [],
    this.images = const [],
  });

  SlideModel copyWith({
    String? id,
    String? name,
    List<CustomTextOverlay>? texts,
    List<CustomImageOverlay>? images,
  }) {
    return SlideModel(
      id: id ?? this.id,
      name: name ?? this.name,
      texts: texts ?? this.texts,
      images: images ?? this.images,
    );
  }
}
