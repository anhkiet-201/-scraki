import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/script_entity.dart';
import '../repositories/script_repository.dart';

@injectable
class RunScriptUseCase {
  final ScriptRepository _repository;

  RunScriptUseCase(this._repository);

  Future<Either<Failure, String>> call(String serial, ScriptEntity script) {
    return _repository.executeScript(serial, script);
  }
}
