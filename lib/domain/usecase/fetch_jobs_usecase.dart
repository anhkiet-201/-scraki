import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../core/error/failures.dart';
import '../../features/poster/domain/entities/poster_data.dart';
import '../../domain/repositories/recruitment_repository.dart';

@lazySingleton
class FetchJobsUseCase {
  final RecruitmentRepository _repository;

  FetchJobsUseCase(this._repository);

  Future<Either<Failure, List<PosterData>>> call() {
    return _repository.fetchJobsFromApi();
  }
}
