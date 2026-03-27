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
  Future<Either<Failure, List<ScriptEntity>>> getAllScripts() async {
    try {
      final scripts = await _localDataSource.getAllScripts();
      return Right(scripts);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveScript(ScriptEntity script) async {
    try {
      await _localDataSource.saveScript(script);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteScript(String id) async {
    try {
      await _localDataSource.deleteScript(id);
      return const Right(null);
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
  Stream<Either<Failure, String>> executeSingleCommandStream(String serial, String command) async* {
    try {
      yield* _adbDataSource.runShellCommandStream(serial, command).map((line) => Right(line));
    } catch (e) {
      yield Left(AdbFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, String>> executeScriptStream(String serial, ScriptEntity script) async* {
    try {
      for (final cmd in script.commands) {
        yield Right('--- Chạy lệnh: $cmd ---');
        yield* _adbDataSource.runShellCommandStream(serial, cmd).map((line) => Right(line));
        yield const Right(''); // Dòng trống phân cách
      }
    } catch (e) {
      if (e is ServerException) {
        yield Left(AdbFailure(e.message));
      } else {
        yield Left(AdbFailure(e.toString()));
      }
    }
  }
}
