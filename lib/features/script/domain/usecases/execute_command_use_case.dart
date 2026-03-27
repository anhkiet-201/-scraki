import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../repositories/script_repository.dart';

@injectable
class ExecuteCommandUseCase {
  final ScriptRepository repository;

  ExecuteCommandUseCase(this.repository);

  Future<Either<Failure, String>> call(String serial, String command) async {
    return await repository.executeSingleCommand(serial, command);
  }
}
