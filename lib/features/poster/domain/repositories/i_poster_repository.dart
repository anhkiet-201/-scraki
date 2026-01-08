import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';

/// Repository interface for Poster operations
///
/// This interface defines the contract for poster-related data operations,
/// following the Repository Pattern and Dependency Inversion Principle.
abstract class IPosterRepository {
  /// Saves poster image to Desktop folder
  ///
  /// Returns [Either<String, String>]:
  /// - Left: Error message if save fails
  /// - Right: Absolute file path if save succeeds
  Future<Either<String, String>> savePosterToDesktop({
    required Uint8List pngBytes,
    required String fileName,
  });
}
