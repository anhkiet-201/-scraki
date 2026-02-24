import 'package:flutter/material.dart';

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

  /// Opacity of the background (0.0–1.0).
  final double backgroundOpacity;

  /// Border radius of the background box (px).
  final double backgroundRadius;

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
    this.backgroundOpacity = 1.0,
    this.backgroundRadius = 8.0,
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
    double? backgroundOpacity,
    double? backgroundRadius,
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
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      backgroundRadius: backgroundRadius ?? this.backgroundRadius,
    );
  }
}
