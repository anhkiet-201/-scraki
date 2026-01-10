import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../poster/domain/entities/poster_data.dart';
import '../repositories/recruitment_repository.dart';

@lazySingleton
class FetchJobsUseCase {
  final RecruitmentRepository _repository;

  FetchJobsUseCase(this._repository);

  Future<Either<Failure, List<PosterData>>> call({
    int page = 1,
    int limit = 10,
  }) {
    return _repository.fetchJobsFromApi(page: page, limit: limit);
  }
}
