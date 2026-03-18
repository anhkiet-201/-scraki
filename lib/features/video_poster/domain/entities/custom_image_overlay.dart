import 'package:flutter/material.dart';

/// Represents a free-form image or GIF overlay on the video canvas.
/// All position values (x, y) are normalized [0.0, 1.0] relative to
/// the 720x1280 virtual canvas.
class CustomImageOverlay {
  final String id;

  /// Network URL, asset path, or base64 data for the image/GIF
  final String imageUrl;

  /// Vị trí file local tạm thời tải từ imageUrl để truyền cho ffmpeg nhanh
  final String? localPath;

  /// Đánh dấu xem ảnh này có phải là định dạng GIF không
  /// (để ffmpeg thêm cờ -ignore_loop 0)
  final bool isGif;

  final double x;
  final double y;

  /// The width constraint of the image. Used to resize dynamically.
  final double width;

  /// The height constraint of the image. Used to resize dynamically.
  final double height;

  final double rotation;

  /// Thời gian bắt đầu xuất hiện (giây)
  final double startTime;

  /// Thời gian biến mất (giây), null = chạy hết video
  final double? endTime;

  /// Border color. Null means no border.
  final Color? borderColor;

  /// Border width in px.
  final double borderWidth;
  final double borderRadius;

  const CustomImageOverlay({
    required this.id,
    required this.imageUrl,
    this.localPath,
    this.isGif = false,
    required this.x,
    required this.y,
    this.width = 200.0, // Default width
    this.height = 200.0, // Default height
    this.rotation = 0.0,
    this.startTime = 0.0,
    this.endTime,
    this.borderColor,
    this.borderWidth = 0.0,
    this.borderRadius = 8.0,
  });

  CustomImageOverlay copyWith({
    String? id,
    String? imageUrl,
    String? localPath,
    bool? isGif,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double? startTime,
    double? endTime,
    bool clearEndTime = false,
    Color? borderColor,
    bool clearBorderColor = false,
    double? borderWidth,
    double? borderRadius,
  }) {
    return CustomImageOverlay(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      isGif: isGif ?? this.isGif,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

}
