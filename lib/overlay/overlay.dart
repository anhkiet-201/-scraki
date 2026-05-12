import 'dart:ui';

import 'package:flutter/material.dart';

abstract class Overlay<T extends OverlayProperties> {
  final T properties;
  final OverlayPannel<T> pannel;
  final OverlayAnimation animationIn;
  final OverlayAnimation animationOut;

  Overlay({
    required this.properties,
    required this.pannel,
    required this.animationIn,
    required this.animationOut,
  });
}

abstract class OverlayProperties {
  final String id;
  final BoxConstraints constraints = const BoxConstraints(
    maxWidth: 720,
    maxHeight: 1280,
  );
  Color color;
  final GlobalKey contentKey = GlobalKey();

  String label = '';

  double x = 0.0;

  double y = 0.0;

  double fontSize = 24.0;

  bool isSelected = false;

  bool isEditing = false;

  bool isHovered = false;

  bool isInteracting = false;

  double opacity = 1.0;

  double rotation = 0.0;

  final GlobalKey captureKey = GlobalKey();

  String get overlayType;

  OverlayProperties({
    required this.id,
    this.color = Colors.white,
  });
}

abstract class OverlayAnimation {}

abstract class OverlayPannel<T extends OverlayProperties> {
  final T properties;

  OverlayPannel({required this.properties});
}

abstract class Pannel {}

class ColorPickerPannel extends Pannel {
  final Color color;

  ColorPickerPannel({required this.color});
}

class SliderPannel extends Pannel {
  final double value;
  final double min;
  final double max;
  final double divisions;

  SliderPannel({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
  });
}

class SelectorPannel extends Pannel {
  final List<String> items;
  final String selectedItem;

  SelectorPannel({required this.items, required this.selectedItem});
}

class FontStylePannel extends Pannel {
  final FontStyle fontStyle;

  FontStylePannel({required this.fontStyle});
}

class TextAlignPannel extends Pannel {
  final TextAlign textAlign;

  TextAlignPannel({required this.textAlign});
}

class TextBackgroundSelectorPannel {}

abstract class TextBackgroundPannel extends Pannel {
  final Color backgroundColor;
  TextBackgroundPannel({required this.backgroundColor});
}

class RectangleTextBackgroundPannel extends TextBackgroundPannel {
  final double backgroundPadding;
  final double backgroundRadius;

  RectangleTextBackgroundPannel({
    required super.backgroundColor,
    required this.backgroundPadding,
    required this.backgroundRadius,
  });
}

class BrushTextBackgroundPannel extends TextBackgroundPannel {
  final double brushIntensity;
  final double brushThickness;
  final double brushComplexity;
  final int textureSeed;
  final double opacity;

  BrushTextBackgroundPannel({
    required super.backgroundColor,
    required this.brushIntensity,
    required this.brushThickness,
    required this.brushComplexity,
    required this.textureSeed,
    required this.opacity,
  });
}

class OverlayPannelSession extends Pannel {
  final List<Pannel> pannels;
  final String sessionTitle;

  OverlayPannelSession({required this.pannels, required this.sessionTitle});
}

// Ví dụ

class TextOverlay extends Overlay<TextOverlayProperties> {
  TextOverlay({
    required super.properties,
    required super.pannel,
    required super.animationIn,
    required super.animationOut,
  });
}

class TextOverlayProperties extends OverlayProperties {
  String text;

  Color? backgroundColor;

  double backgroundOpacity = 1.0;

  double backgroundRadius = 0.0;

  TextAlign textAlign = TextAlign.left;

  TextBackgroundStyle? backgroundStyle;

  @override
  String get overlayType => 'TEXT';

  TextOverlayProperties({
    required this.text,
    required super.id,
  });
}

class TextOverlayPannel extends OverlayPannel<TextOverlayProperties> {
  TextOverlayPannel({required super.properties});
}

class TextOverlayAnimationIn extends OverlayAnimation {
  TextOverlayAnimationIn();
}

class TextOverlayAnimationOut extends OverlayAnimation {
  TextOverlayAnimationOut();
}

class ImageOverlay extends Overlay<ImageOverlayProperties> {
  ImageOverlay({
    required super.properties,
    required super.pannel,
    required super.animationIn,
    required super.animationOut,
  });
}

class ImageOverlayProperties extends OverlayProperties {
  final String imageUrl;
  final String? localPath;
  final bool isGif;
  final double startTime;
  final double? endTime;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  double width;
  double height;

  @override
  String get overlayType => 'IMAGE';

  double get backgroundRadius => borderRadius;

  ImageOverlayProperties({
    required this.imageUrl,
    this.localPath,
    this.isGif = false,
    double x = 0.0,
    double y = 0.0,
    this.width = 200.0,
    this.height = 200.0,
    double rotation = 0.0,
    this.startTime = 0.0,
    this.endTime,
    this.borderColor,
    this.borderWidth = 0.0,
    this.borderRadius = 8.0,
    required super.id,
  }) {
    this.x = x;
    this.y = y;
    this.rotation = rotation;
  }
}

class ImageOverlayPannel extends OverlayPannel<ImageOverlayProperties> {
  ImageOverlayPannel({required super.properties});
}
