import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/features/poster/domain/repositories/i_poster_repository.dart';

/// Use case for saving poster image to Desktop
///
/// This use case orchestrates the save poster workflow,
/// following Clean Architecture and Single Responsibility Principle.
@injectable
class SavePosterUseCase {
  final IPosterRepository _repository;

  SavePosterUseCase(this._repository);

  /// Executes the save poster use case
  ///
  /// Parameters:
  /// - [pngBytes]: PNG image data as bytes
  /// - [fileName]: Name of the file to save (e.g., "JobTitle_timestamp.png")
  ///
  /// Returns [Either<String, String>]:
  /// - Left: Error message if operation fails
  /// - Right: Absolute file path if operation succeeds
  Future<Either<String, String>> call({
    required Uint8List pngBytes,
    required String fileName,
  }) async {
    return _repository.savePosterToDesktop(
      pngBytes: pngBytes,
      fileName: fileName,
    );
  }
}
