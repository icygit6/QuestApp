import '../../../core/errors/failures.dart';
import 'auth_provider_type.dart';
import 'user_entity.dart';

abstract interface class AuthRepository {
  /// Attempts DummyJSON login and persists auth data.
  Future<Either<Failure, UserEntity>> login({
    required AuthProviderType provider,
    required String username,
    required String password,
  });

  /// Registers a user through DummyJSON and persists the returned identity.
  Future<Either<Failure, UserEntity>> register({
    required AuthProviderType provider,
    required String username,
    required String email,
    required String password,
  });

  /// Restores the last saved user session if a token exists.
  Future<Either<Failure, UserEntity?>> restoreSession();

  /// Clears all authentication credentials.
  Future<void> logout();
}
