import 'package:scraki/features/video_poster/domain/entities/slide_model.dart';

enum PosterPlatformSet {
  tiktok,
  facebook,
}

extension PosterPlatformSetExtension on PosterPlatformSet {
  String get label {
    switch (this) {
      case PosterPlatformSet.tiktok:
        return 'Tiktok set';
      case PosterPlatformSet.facebook:
        return 'Facebook set';
    }
  }

  String get prefix {
    switch (this) {
      case PosterPlatformSet.tiktok:
        return 'Tik_Set';
      case PosterPlatformSet.facebook:
        return 'Fb_Set';
    }
  }
}

enum FacebookSubtype {
  groups,
  feeds,
}

extension FacebookSubtypeExtension on FacebookSubtype {
  String get label {
    switch (this) {
      case FacebookSubtype.groups:
        return 'Groups';
      case FacebookSubtype.feeds:
        return 'Feeds';
    }
  }
}

/// Configuration for Image Poster generation.
class ImagePosterConfig {
  final int outputCount;
  final List<SlideModel> slides;
  final String outputFormat;
  final int width;
  final int height;
  final String? outputDir;
  final PosterPlatformSet platformSet;
  final FacebookSubtype facebookSubtype;

  const ImagePosterConfig({
    required this.outputCount,
    required this.slides,
    this.outputFormat = 'jpg',
    this.width = 1080,
    this.height = 1350,
    this.outputDir,
    this.platformSet = PosterPlatformSet.tiktok,
    this.facebookSubtype = FacebookSubtype.groups,
  });

  ImagePosterConfig copyWith({
    int? outputCount,
    List<SlideModel>? slides,
    String? outputFormat,
    int? width,
    int? height,
    String? outputDir,
    PosterPlatformSet? platformSet,
    FacebookSubtype? facebookSubtype,
  }) {
    return ImagePosterConfig(
      outputCount: outputCount ?? this.outputCount,
      slides: slides ?? this.slides,
      outputFormat: outputFormat ?? this.outputFormat,
      width: width ?? this.width,
      height: height ?? this.height,
      outputDir: outputDir ?? this.outputDir,
      platformSet: platformSet ?? this.platformSet,
      facebookSubtype: facebookSubtype ?? this.facebookSubtype,
    );
  }
}

