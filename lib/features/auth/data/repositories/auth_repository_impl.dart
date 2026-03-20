import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:scraki/core/error/failures.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_token_model.dart';

@LazySingleton(as: IAuthRepository)
class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<AuthToken>>> getAuthTokens(
    String groupCollection,
    String serial,
  ) async {
    return await _remoteDataSource.getAuthTokens(groupCollection, serial);
  }

  @override
  Future<Either<Failure, Unit>> saveAuthTokens(
    String groupCollection,
    String serial,
    List<AuthToken> tokens,
  ) async {
    final rawText = tokens
        .map((t) => AuthTokenModel.fromEntity(t).toRawLine())
        .join('\n');
    return await _remoteDataSource.saveRawAuthTokens(
      groupCollection,
      serial,
      rawText,
    );
  }

  @override
  Future<Either<Failure, Unit>> addAuthToken(
    String groupCollection,
    String serial,
    AuthToken token,
  ) async {
    final tokensEither = await getAuthTokens(groupCollection, serial);
    return await tokensEither.fold(
      (failure) => Left(failure),
      (tokens) async {
        final newList = List<AuthToken>.from(tokens)..add(token);
        return await saveAuthTokens(groupCollection, serial, newList);
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> deleteAuthToken(
    String groupCollection,
    String serial,
    String id,
  ) async {
    final tokensEither = await getAuthTokens(groupCollection, serial);
    return await tokensEither.fold(
      (failure) => Left(failure),
      (tokens) async {
        final newList = tokens.where((t) => t.id != id).toList();
        return await saveAuthTokens(groupCollection, serial, newList);
      },
    );
  }
}
