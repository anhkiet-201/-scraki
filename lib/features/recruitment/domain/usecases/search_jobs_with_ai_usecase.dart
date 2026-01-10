import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../poster/domain/entities/poster_data.dart';
import '../repositories/recruitment_repository.dart';

@lazySingleton
class SearchJobsWithAiUseCase {
  final RecruitmentRepository _repository;

  SearchJobsWithAiUseCase(this._repository);

  Future<Either<Failure, List<PosterData>>> call(
    String query, {
    int page = 1,
    int limit = 10,
  }) {
    return _repository.searchJobs(query, page: page, limit: limit);
  }
}
