import '../../../core/errors/failures.dart';
import 'auth_provider_type.dart';
import 'auth_repository.dart';
import 'user_entity.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes registration through DummyJSON.
  Future<Either<Failure, UserEntity>> call({
    required AuthProviderType provider,
    required String username,
    required String email,
    required String password,
  }) {
    return _repository.register(
      provider: provider,
      username: username,
      email: email,
      password: password,
    );
  }
}
