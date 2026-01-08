import 'dart:io';
import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/features/poster/domain/repositories/i_poster_repository.dart';

/// Implementation of [IPosterRepository] with cross-platform support
///
/// Provides file I/O operations to save poster images to Desktop folder.
/// Supports macOS and Windows platforms.
///
/// SOLID Principles:
/// - Single Responsibility: Only handles file I/O for posters
/// - Open/Closed: Can be extended for Linux support without modification
/// - Liskov Substitution: Fully implements IPosterRepository contract
/// - Dependency Inversion: Depends on Either abstraction
@LazySingleton(as: IPosterRepository)
class PosterRepositoryImpl implements IPosterRepository {
  @override
  Future<Either<String, String>> savePosterToDesktop({
    required Uint8List pngBytes,
    required String fileName,
  }) async {
    try {
      final desktopPath = _getDesktopPath();
      if (desktopPath == null) {
        return left('Không thể xác định thư mục Desktop');
      }

      final filePath = '$desktopPath${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      return right(file.path);
    } catch (e) {
      return left('Lỗi khi lưu file: ${e.toString()}');
    }
  }

  /// Gets Desktop folder path based on platform
  ///
  /// Returns:
  /// - macOS: $HOME/Desktop (e.g., /Users/username/Desktop)
  /// - Windows: %USERPROFILE%\Desktop (e.g., C:\Users\username\Desktop)
  /// - Linux: null (not supported yet)
  String? _getDesktopPath() {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      return home != null ? '$home/Desktop' : null;
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      return userProfile != null ? '$userProfile\\Desktop' : null;
    }
    // Linux support can be added here if needed: $HOME/Desktop
    return null;
  }
}
