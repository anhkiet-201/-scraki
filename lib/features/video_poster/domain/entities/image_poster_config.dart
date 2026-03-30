import 'package:scraki/features/video_poster/domain/entities/slide_model.dart';

/// Configuration for Image Poster generation.
class ImagePosterConfig {
  final int outputCount;
  final List<SlideModel> slides;
  final String outputFormat;
  final int width;
  final int height;
  final String? outputDir;

  const ImagePosterConfig({
    required this.outputCount,
    required this.slides,
    this.outputFormat = 'png',
    this.width = 1080,
    this.height = 1350,
    this.outputDir,
  });

  ImagePosterConfig copyWith({
    int? outputCount,
    List<SlideModel>? slides,
    String? outputFormat,
    int? width,
    int? height,
    String? outputDir,
  }) {
    return ImagePosterConfig(
      outputCount: outputCount ?? this.outputCount,
      slides: slides ?? this.slides,
      outputFormat: outputFormat ?? this.outputFormat,
      width: width ?? this.width,
      height: height ?? this.height,
      outputDir: outputDir ?? this.outputDir,
    );
  }
}
