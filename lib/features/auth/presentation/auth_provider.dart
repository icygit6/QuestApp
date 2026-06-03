import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_local_datasource.dart';
import '../data/auth_remote_datasource.dart';
import '../data/auth_repository_impl.dart';
import '../data/backendless_auth_remote_datasource.dart';
import '../data/favqs_auth_remote_datasource.dart';
import '../domain/auth_provider_type.dart';
import '../domain/auth_repository.dart';
import '../domain/login_usecase.dart';
import '../domain/register_usecase.dart';
import '../domain/user_entity.dart';

final dummyAuthRemoteDataSourceProvider = Provider<DummyAuthRemoteDataSource>(
  (ref) => DummyAuthRemoteDataSource(ref.watch(dioClientProvider)),
);

final favqsAuthRemoteDataSourceProvider = Provider<FavqsAuthRemoteDataSource>(
  (ref) => FavqsAuthRemoteDataSource(ref.watch(favqsApiClientProvider)),
);

final backendlessAuthRemoteDataSourceProvider =
    Provider<BackendlessAuthRemoteDataSource>(
      (ref) => BackendlessAuthRemoteDataSource(
        ref.watch(backendlessApiClientProvider),
      ),
    );

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSource(
    secureStorage: ref.watch(secureStorageProvider),
    preferences: ref.watch(sharedPreferencesProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    dummyRemoteDataSource: ref.watch(dummyAuthRemoteDataSourceProvider),
    favqsRemoteDataSource: ref.watch(favqsAuthRemoteDataSourceProvider),
    backendlessRemoteDataSource: ref.watch(
      backendlessAuthRemoteDataSourceProvider,
    ),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  ),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
);

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    repository: ref.watch(authRepositoryProvider),
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
  )..restoreSession();
});

final authProviderSelectionProvider = StateProvider<AuthProviderType>(
  (ref) => AuthProviderType.dummy,
);

enum AuthStatus { loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({required this.status, this.user, this.message});

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated(UserEntity user)
    : this(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.error(String message)
    : this(status: AuthStatus.error, message: message);

  final AuthStatus status;
  final UserEntity? user;
  final String? message;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required AuthRepository repository,
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
  }) : _repository = repository,
       _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       super(const AuthState.loading());

  final AuthRepository _repository;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;

  /// Restores persisted auth state from secure storage.
  Future<void> restoreSession() async {
    state = const AuthState.loading();
    final result = await _repository.restoreSession();
    state = result.fold(
      (failure) => AuthState.error(failure.message),
      (user) => user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user),
    );
  }

  /// Logs in through the selected provider.
  Future<void> login(
    AuthProviderType provider,
    String username,
    String password,
  ) async {
    state = const AuthState.loading();
    final result = await _loginUseCase(provider, username.trim(), password);
    state = result.fold(
      (failure) => AuthState.error(failure.message),
      AuthState.authenticated,
    );
  }

  /// Registers a new character through the selected provider.
  Future<void> register({
    required AuthProviderType provider,
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    final result = await _registerUseCase(
      provider: provider,
      username: username.trim(),
      email: email.trim(),
      password: password,
    );
    state = result.fold(
      (failure) => AuthState.error(failure.message),
      AuthState.authenticated,
    );
  }

  /// Logs out and clears credentials.
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.unauthenticated();
  }
}
