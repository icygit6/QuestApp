import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_provider_type.dart';
import '../domain/auth_repository.dart';
import '../domain/user_entity.dart';
import 'auth_local_datasource.dart';
import 'auth_remote_datasource.dart';
import 'backendless_auth_remote_datasource.dart';
import 'favqs_auth_remote_datasource.dart';
import 'user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required DummyAuthRemoteDataSource dummyRemoteDataSource,
    required FavqsAuthRemoteDataSource favqsRemoteDataSource,
    required BackendlessAuthRemoteDataSource backendlessRemoteDataSource,
    required AuthLocalDataSource localDataSource,
  }) : _dummyRemoteDataSource = dummyRemoteDataSource,
       _favqsRemoteDataSource = favqsRemoteDataSource,
       _backendlessRemoteDataSource = backendlessRemoteDataSource,
       _localDataSource = localDataSource;

  final DummyAuthRemoteDataSource _dummyRemoteDataSource;
  final FavqsAuthRemoteDataSource _favqsRemoteDataSource;
  final BackendlessAuthRemoteDataSource _backendlessRemoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, UserEntity>> login({
    required AuthProviderType provider,
    required String username,
    required String password,
  }) async {
    try {
      final user = switch (provider) {
        AuthProviderType.dummy => await _dummyRemoteDataSource.login(
          username: username,
          password: password,
        ),
        AuthProviderType.favqs => await _favqsRemoteDataSource.login(
          username: username,
          password: password,
        ),
        AuthProviderType.backendless =>
          await _backendlessRemoteDataSource.login(
            username: username,
            password: password,
          ),
      };
      await _localDataSource.saveUser(UserModel.fromEntity(user));
      return Right(user);
    } catch (error) {
      if (error is Failure) {
        return Left(error);
      }
      return Left(mapDioFailure(error));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required AuthProviderType provider,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      if (provider == AuthProviderType.favqs) {
        return const Left(
          ValidationFailure('FavQs registration is not supported.'),
        );
      }

      if (provider == AuthProviderType.backendless) {
        await _backendlessRemoteDataSource.register(
          username: username,
          email: email,
          password: password,
        );
        final loginUser = await _backendlessRemoteDataSource.login(
          username: email.isNotEmpty ? email : username,
          password: password,
        );
        await _localDataSource.saveUser(UserModel.fromEntity(loginUser));
        return Right(loginUser);
      }

      final user = await _dummyRemoteDataSource.register(
        username: username,
        email: email,
        password: password,
      );
      await _localDataSource.saveUser(UserModel.fromEntity(user));
      return Right(user);
    } catch (error) {
      if (error is Failure) {
        return Left(error);
      }
      return Left(mapDioFailure(error));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> restoreSession() async {
    try {
      return Right(await _localDataSource.restoreUser());
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<void> logout() => _localDataSource.clear();
}
