import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/exceptions.dart';
import 'package:scraki/core/error/failures.dart';
import 'package:scraki/features/device/data/datasources/adb_remote_data_source.dart';
import 'package:scraki/features/script/domain/entities/script_entity.dart';
import 'package:scraki/features/script/domain/repositories/script_repository.dart';
import 'package:scraki/features/script/data/datasources/local_script_data_source.dart';
import 'package:scraki/features/script/data/datasources/remote_script_data_source.dart';
import 'package:scraki/features/script/data/models/script_model.dart';

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
    yield* _executeCommandInternal(serial, command);
  }

  @override
  Stream<Either<Failure, String>> executeScriptStream(String serial, ScriptEntity script) async* {
    for (final cmd in script.commands) {
      yield* _executeCommandInternal(serial, cmd);
      yield const Right(''); // Dòng trống phân cách
    }
  }

  Stream<Either<Failure, String>> _executeCommandInternal(String serial, String cmd) async* {
    try {
      final trimmedCmd = cmd.trim();
      if (trimmedCmd.isEmpty) return;

      final adbRegex = RegExp(r'^adb([^a-zA-Z0-9]|$)', caseSensitive: false);

      final adbMatch = adbRegex.firstMatch(trimmedCmd);
      if (adbMatch != null) {
        final rawCmd = trimmedCmd.substring(adbMatch.end).trim();
        yield* _adbDataSource
            .runRawAdbCommandStream(serial, rawCmd)
            .map<Either<Failure, String>>((line) => Right(line))
            .handleError((Object e) {
          if (e is ServerException) return Left<Failure, String>(AdbFailure(e.message));
          return Left<Failure, String>(AdbFailure(e.toString()));
        });
      } else {
        yield* _adbDataSource
            .runShellCommandStream(serial, trimmedCmd)
            .map<Either<Failure, String>>((line) => Right(line))
            .handleError((Object e) {
          if (e is ServerException) return Left<Failure, String>(AdbFailure(e.message));
          return Left<Failure, String>(AdbFailure(e.toString()));
        });
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
