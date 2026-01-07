import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../poster/domain/entities/poster_data.dart';

/// Interface for fetching recruitment data.
/// Implementations can be AI-based (parsing text) or API-based.
abstract class RecruitmentRepository {
  /// Parses unstructured job description text into structured PosterData using AI.
  Future<Either<Failure, PosterData>> parseJobDescription(String rawText);

  /// Fetches a list of jobs from the recruitment API.
  /// Note: This returns a List of dynamic or a specific Job entity, not PosterData directly.
  /// For simplicity in this feature, we might map it to a partial PosterData or a dedicated Job entity.
  /// Let's return a specific entity. But for now, to keep it simple for the Poster feature:
  Future<Either<Failure, List<PosterData>>> fetchJobsFromApi();
  Future<Either<Failure, PosterData>> fetchJobDetail(String slug);
}
