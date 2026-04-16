import 'package:flutter/material.dart';

enum TextAnimationType {
  none,
  fade,
  zoom,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
}

enum TextBackgroundStyle {
  rectangle,
  brush,
}

/// Represents a free-form text overlay on the video canvas.
/// All position values (x, y) are normalized [0.0, 1.0] relative to
/// the 720x1280 virtual canvas.
class CustomTextOverlay {
  final String id;
  final String label;
  final double x;
  final double y;
  final double fontSize;

  /// Line height multiplier (null = system default ~1.2).
  final double? textHeight;

  final Color color;
  final FontWeight fontWeight;
  final FontStyle fontStyle;
  final TextAlign textAlign;

  /// Background color of the text box. Null means fully transparent.
  final Color? backgroundColor;

  /// Background style of the text box.
  final TextBackgroundStyle backgroundStyle;

  /// Opacity of the background (0.0–1.0).
  final double backgroundOpacity;

  /// Border radius of the background box (px).
  final double backgroundRadius;
  final String? fontFamily;
  final double rotation;
  final double letterSpacing;
  final Color? backgroundBorderColor;
  final double backgroundBorderWidth;

  /// Stroke (outline) color. Null means no stroke.
  final Color? strokeColor;

  /// Stroke width in px.
  final double strokeWidth;

  /// Time in seconds when the text should appear.
  final double startTime;

  /// Time in seconds when the text should disappear. Null means until the end.
  final double? endTime;

  final TextAnimationType animationInType;
  final double animationInDuration;
  final TextAnimationType animationOutType;
  final double animationOutDuration;

  bool get isAnimated =>
      animationInType != TextAnimationType.none ||
      animationOutType != TextAnimationType.none;

  const CustomTextOverlay({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    this.fontSize = 40.0,
    this.textHeight = 1.2,
    this.color = Colors.white,
    this.fontWeight = FontWeight.bold,
    this.fontStyle = FontStyle.normal,
    this.textAlign = TextAlign.center,
    this.backgroundColor,
    this.backgroundStyle = TextBackgroundStyle.rectangle,
    this.backgroundOpacity = 1.0,
    this.backgroundRadius = 8.0,
    this.fontFamily,
    this.rotation = 0.0,
    this.letterSpacing = 0.0,
    this.backgroundBorderColor,
    this.backgroundBorderWidth = 0.0,
    this.strokeColor,
    this.strokeWidth = 0.0,
    this.startTime = 0.0,
    this.endTime,
    this.animationInType = TextAnimationType.none,
    this.animationInDuration = 0.1,
    this.animationOutType = TextAnimationType.none,
    this.animationOutDuration = 0.1,
  });

  CustomTextOverlay copyWith({
    String? id,
    String? label,
    double? x,
    double? y,
    double? fontSize,
    double? textHeight,
    bool clearTextHeight = false,
    Color? color,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextAlign? textAlign,
    Color? backgroundColor,
    bool clearBackgroundColor = false,
    TextBackgroundStyle? backgroundStyle,
    double? backgroundOpacity,
    double? backgroundRadius,
    String? fontFamily,
    double? rotation,
    double? letterSpacing,
    Color? backgroundBorderColor,
    double? backgroundBorderWidth,
    bool clearBackgroundBorderColor = false,
    Color? strokeColor,
    bool clearStrokeColor = false,
    double? strokeWidth,
    double? startTime,
    double? endTime,
    bool clearEndTime = false,
    TextAnimationType? animationInType,
    double? animationInDuration,
    TextAnimationType? animationOutType,
    double? animationOutDuration,
  }) {
    return CustomTextOverlay(
      id: id ?? this.id,
      label: label ?? this.label,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      textHeight: clearTextHeight ? null : (textHeight ?? this.textHeight),
      color: color ?? this.color,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      textAlign: textAlign ?? this.textAlign,
      backgroundColor: clearBackgroundColor
          ? null
          : (backgroundColor ?? this.backgroundColor),
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      backgroundRadius: backgroundRadius ?? this.backgroundRadius,
      fontFamily: fontFamily ?? this.fontFamily,
      rotation: rotation ?? this.rotation,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      backgroundBorderColor: clearBackgroundBorderColor
          ? null
          : (backgroundBorderColor ?? this.backgroundBorderColor),
      backgroundBorderWidth:
          backgroundBorderWidth ?? this.backgroundBorderWidth,
      strokeColor: clearStrokeColor ? null : (strokeColor ?? this.strokeColor),
      strokeWidth: strokeWidth ?? this.strokeWidth,
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      animationInType: animationInType ?? this.animationInType,
      animationInDuration: animationInDuration ?? this.animationInDuration,
      animationOutType: animationOutType ?? this.animationOutType,
      animationOutDuration: animationOutDuration ?? this.animationOutDuration,
    );
  }
}

