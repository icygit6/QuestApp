import '../../../core/errors/failures.dart';
import 'auth_provider_type.dart';
import 'auth_repository.dart';
import 'user_entity.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes login with username and password.
  Future<Either<Failure, UserEntity>> call(
    AuthProviderType provider,
    String username,
    String password,
  ) {
    return _repository.login(
      provider: provider,
      username: username,
      password: password,
    );
  }
}
