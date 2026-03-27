import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../device/data/datasources/adb_remote_data_source.dart';
import '../../domain/entities/script_entity.dart';
import '../../domain/repositories/script_repository.dart';
import '../datasources/local_script_data_source.dart';

@LazySingleton(as: ScriptRepository)
class ScriptRepositoryImpl implements ScriptRepository {
  final IAdbRemoteDataSource _adbDataSource;
  final LocalScriptDataSource _localDataSource;

  ScriptRepositoryImpl(this._adbDataSource, @Named('local_script') this._localDataSource);

  @override
  Future<Either<Failure, List<ScriptEntity>>> getPredefinedScripts() async {
    try {
      final scripts = await _localDataSource.getPredefinedScripts();
      return Right(scripts);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> executeSingleCommand(String serial, String command) async {
    try {
      final output = await _adbDataSource.runShellCommand(serial, command);
      return Right(output);
    } on ServerException catch (e) {
      return Left(AdbFailure(e.message));
    } catch (e) {
      return Left(AdbFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> executeScript(String serial, ScriptEntity script) async {
    try {
      final StringBuffer buffer = StringBuffer();
      for (final cmd in script.commands) {
        buffer.writeln('--- Chạy lệnh: $cmd ---');
        final output = await _adbDataSource.runShellCommand(serial, cmd);
        buffer.writeln(output);
        buffer.writeln();
      }
      return Right(buffer.toString());
    } on ServerException catch (e) {
      return Left(AdbFailure(e.message));
    } catch (e) {
      return Left(AdbFailure(e.toString()));
    }
  }
}
