import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/poster_data.dart';
import '../../domain/repositories/recruitment_repository.dart';

@lazySingleton
class ParseJobTextUseCase {
  final RecruitmentRepository _repository;

  ParseJobTextUseCase(this._repository);

  Future<Either<Failure, PosterData>> call(String rawText) {
    return _repository.parseJobDescription(rawText);
  }
}
