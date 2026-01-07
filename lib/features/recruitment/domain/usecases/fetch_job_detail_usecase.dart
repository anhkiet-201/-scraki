import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../poster/domain/entities/poster_data.dart';
import '../repositories/recruitment_repository.dart';

@lazySingleton
class FetchJobDetailUseCase {
  final RecruitmentRepository _repository;

  FetchJobDetailUseCase(this._repository);

  Future<Either<Failure, PosterData>> call(String slug) {
    return _repository.fetchJobDetail(slug);
  }
}
