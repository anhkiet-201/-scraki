import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/script_entity.dart';
import '../repositories/script_repository.dart';

@lazySingleton
class SaveScriptUseCase {
  final ScriptRepository _repository;

  SaveScriptUseCase(this._repository);

  Future<Either<Failure, void>> call(ScriptEntity script) {
    return _repository.saveScript(script);
  }
}
