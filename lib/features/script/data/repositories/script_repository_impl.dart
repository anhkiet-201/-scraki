import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../device/data/datasources/adb_remote_data_source.dart';
import '../../domain/entities/script_entity.dart';
import '../../domain/repositories/script_repository.dart';
import '../datasources/local_script_data_source.dart';
import '../datasources/remote_script_data_source.dart';
import '../models/script_model.dart';

@LazySingleton(as: ScriptRepository)
class ScriptRepositoryImpl implements ScriptRepository {
  final IAdbRemoteDataSource _adbDataSource;
  final LocalScriptDataSource _localDataSource;
  final RemoteScriptDataSource _remoteDataSource;

  ScriptRepositoryImpl(
    this._adbDataSource,
    @Named('local_script') this._localDataSource,
    this._remoteDataSource,
  );

  @override
  Stream<Either<Failure, List<ScriptEntity>>> watchAllScripts() {
    return _remoteDataSource.watchAllScripts().map<Either<Failure, List<ScriptEntity>>>((models) {
      return Right<Failure, List<ScriptEntity>>(models.map((m) => m.toEntity()).toList());
    }).handleError((Object e) {
      return Left<Failure, List<ScriptEntity>>(ApiFailure(e.toString()));
    });
  }

  @override
  Future<Either<Failure, List<ScriptEntity>>> getAllScripts() async {
    try {
      final scripts = await _remoteDataSource.getAllScripts();
      return Right(scripts.map((m) => m.toEntity()).toList());
    } catch (e) {
      // Fallback to local if remote fails
      try {
        final localScripts = await _localDataSource.getAllScripts();
        return Right(localScripts);
      } catch (ce) {
        return Left(ApiFailure(e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, void>> saveScript(ScriptEntity script) async {
    try {
      final model = ScriptModel.fromEntity(script);
      await _remoteDataSource.saveScript(model);
      await _localDataSource.saveScript(script); // Sync local cache
      return const Right(null);
    } catch (e) {
      return Left(ApiFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteScript(String id) async {
    try {
      await _remoteDataSource.deleteScript(id);
      await _localDataSource.deleteScript(id);
      return const Right(null);
    } catch (e) {
      return Left(ApiFailure(e.toString()));
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
