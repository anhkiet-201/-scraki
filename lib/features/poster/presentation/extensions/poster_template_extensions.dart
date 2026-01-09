import 'package:flutter/widgets.dart';
import 'package:scraki/features/poster/domain/entities/poster_data.dart';
import 'package:scraki/features/poster/domain/enums/poster_template_type.dart';
import 'package:scraki/features/poster/presentation/store/poster_customization_store.dart';
import 'package:scraki/features/poster/presentation/widgets/abstract_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/bold_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/corporate_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/creative_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/elegant_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/geometric_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/high_contrast_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/luxury_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/minimalist_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/modern_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/nature_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/neon_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/playful_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/professional_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/retro_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/swiss_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/tech_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/typography_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/urban_poster.dart';
import 'package:scraki/features/poster/presentation/widgets/vintage_poster.dart';

extension PosterTemplateTypeX on PosterTemplateType {
  Widget buildWidget({
    Key? key,
    required PosterData data,
    double width = 360,
    double height = 514,
    required PosterCustomizationStore customizationStore,
  }) {
    switch (this) {
      case PosterTemplateType.modern:
        return ModernPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.minimalist:
        return MinimalistPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.bold:
        return BoldPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.corporate:
        return CorporatePoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.creative:
        return CreativePoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.tech:
        return TechPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.elegant:
        return ElegantPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.playful:
        return PlayfulPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.retro:
        return RetroPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.swiss:
        return SwissPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.highContrast:
        return HighContrastPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.typography:
        return TypographyPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.nature:
        return NaturePoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.urban:
        return UrbanPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.luxury:
        return LuxuryPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.geometric:
        return GeometricPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.vintage:
        return VintagePoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.neon:
        return NeonPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.abstract:
        return AbstractPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
      case PosterTemplateType.professional:
        return ProfessionalPoster(
          key: key,
          data: data,
          width: width,
          height: height,
          customizationStore: customizationStore,
        );
    }
  }
}
