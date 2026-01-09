enum PosterTemplateType {
  modern,
  minimalist,
  bold,
  corporate,
  creative,
  tech,
  elegant,
  playful,
  retro,
  swiss,
  highContrast,
  typography,
  nature,
  urban,
  luxury,
  geometric,
  vintage,
  neon,
  abstract,
  professional;

  String get label {
    switch (this) {
      case PosterTemplateType.modern:
        return 'Modern';
      case PosterTemplateType.minimalist:
        return 'Minimalist';
      case PosterTemplateType.bold:
        return 'Bold';
      case PosterTemplateType.corporate:
        return 'Corporate';
      case PosterTemplateType.creative:
        return 'Creative';
      case PosterTemplateType.tech:
        return 'Tech';
      case PosterTemplateType.elegant:
        return 'Elegant';
      case PosterTemplateType.playful:
        return 'Playful';
      case PosterTemplateType.retro:
        return 'Retro';
      case PosterTemplateType.swiss:
        return 'Swiss';
      case PosterTemplateType.highContrast:
        return 'High Contrast';
      case PosterTemplateType.typography:
        return 'Typography';
      case PosterTemplateType.nature:
        return 'Nature';
      case PosterTemplateType.urban:
        return 'Urban';
      case PosterTemplateType.luxury:
        return 'Luxury';
      case PosterTemplateType.geometric:
        return 'Geometric';
      case PosterTemplateType.vintage:
        return 'Vintage';
      case PosterTemplateType.neon:
        return 'Neon';
      case PosterTemplateType.abstract:
        return 'Abstract';
      case PosterTemplateType.professional:
        return 'Professional';
    }
  }
}
