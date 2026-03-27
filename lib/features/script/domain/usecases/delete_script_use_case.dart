import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../repositories/script_repository.dart';

@lazySingleton
class DeleteScriptUseCase {
  final ScriptRepository _repository;

  DeleteScriptUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) {
    return _repository.deleteScript(id);
  }
}
