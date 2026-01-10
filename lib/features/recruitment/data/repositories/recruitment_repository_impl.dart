import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../datasources/recruitment_remote_data_source.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/recruitment_repository.dart';
import '../../../poster/domain/entities/poster_data.dart';

@LazySingleton(as: RecruitmentRepository)
class RecruitmentRepositoryImpl implements RecruitmentRepository {
  final RecruitmentRemoteDataSource _dataSource;

  RecruitmentRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<PosterData>>> fetchJobs({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await _dataSource.fetchJobs(page: page, limit: limit);
      return right(result);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return left(
          ConnectionFailure(
            'Network timeout or connection error: ${e.message}',
          ),
        );
      } else if (e.type == DioExceptionType.badResponse) {
        return left(ApiFailure('Bad response: ${e.response?.statusCode}'));
      }
      return left(ApiFailure('Dio Error: ${e.message}', e));
    } catch (e, stackTrace) {
      return left(ApiFailure('Failed to fetch jobs: $e', e, stackTrace));
    }
  }

  @override
  Future<Either<Failure, List<PosterData>>> searchJobs(
    String query, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await _dataSource.searchJobs(
        query,
        page: page,
        limit: limit,
      );
      return right(result);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return left(
          ConnectionFailure(
            'Network timeout or connection error: ${e.message}',
          ),
        );
      } else if (e.type == DioExceptionType.badResponse) {
        return left(ApiFailure('Bad response: ${e.response?.statusCode}'));
      }
      return left(ApiFailure('Dio Error: ${e.message}', e));
    } catch (e, stackTrace) {
      return left(ApiFailure('Failed to search jobs: $e', e, stackTrace));
    }
  }

  @override
  Future<Either<Failure, PosterData>> parseJobDescription(
    String rawText,
  ) async {
    try {
      final result = await _dataSource.parseJobDescription(rawText);
      return right(result);
    } catch (e, stackTrace) {
      return left(ParsingFailure('Gemini Error: $e', e, stackTrace));
    }
  }

  @override
  Future<Either<Failure, PosterData>> fetchJobDetail(String slug) async {
    try {
      final result = await _dataSource.fetchJobDetail(slug);
      return right(result);
    } catch (e, stackTrace) {
      return left(ApiFailure('Failed to fetch job detail', e, stackTrace));
    }
  }
}
