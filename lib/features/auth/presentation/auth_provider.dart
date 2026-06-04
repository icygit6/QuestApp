import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../services/auth_service.dart';
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

/// Google Sign-In + Firebase Authentication service. Stateless and safe to
/// construct even when Firebase is not initialised (see [GoogleAuthService]).
final googleAuthServiceProvider = Provider<GoogleAuthService>(
  (ref) => GoogleAuthService(),
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
    googleAuthService: ref.watch(googleAuthServiceProvider),
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
    required GoogleAuthService googleAuthService,
  }) : _repository = repository,
       _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _googleAuthService = googleAuthService,
       super(const AuthState.loading());

  final AuthRepository _repository;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GoogleAuthService _googleAuthService;

  /// Restores persisted auth state.
  ///
  /// Tries the credential providers (DummyJSON / FavQs / Backendless) first via
  /// secure storage. If none is persisted, falls back to a Firebase/Google
  /// session, which Firebase persists on the device across restarts.
  Future<void> restoreSession() async {
    state = const AuthState.loading();
    final result = await _repository.restoreSession();
    state = result.fold((failure) => AuthState.error(failure.message), (user) {
      if (user != null) {
        return AuthState.authenticated(user);
      }
      final googleUser = _googleAuthService.getCurrentUser();
      if (googleUser != null) {
        return AuthState.authenticated(_mapFirebaseUser(googleUser));
      }
      return const AuthState.unauthenticated();
    });
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

  /// Logs in with Google via Firebase Authentication.
  ///
  /// A `null` credential means the user dismissed the Google picker, so we
  /// quietly return to the unauthenticated state without an error toast.
  Future<void> loginWithGoogle() async {
    state = const AuthState.loading();
    try {
      final credential = await _googleAuthService.signInWithGoogle();
      final user = credential?.user;
      if (user == null) {
        state = const AuthState.unauthenticated();
        return;
      }
      state = AuthState.authenticated(_mapFirebaseUser(user));
    } catch (error) {
      state = AuthState.error(_readableError(error));
    }
  }

  /// Logs out and clears credentials from every provider, including Google.
  Future<void> logout() async {
    await _repository.logout();
    await _googleAuthService.signOut();
    state = const AuthState.unauthenticated();
  }

  /// Adapts a Firebase [User] to the app's [UserEntity].
  ///
  /// Google sign-in does not flow through the username/password datasources, so
  /// it is tagged with the default [AuthProviderType] and is not persisted in
  /// secure storage — Firebase manages its own session.
  UserEntity _mapFirebaseUser(User user) {
    final displayName = (user.displayName ?? '').trim();
    final parts = displayName.isEmpty
        ? const <String>[]
        : displayName.split(RegExp(r'\s+'));
    final email = user.email ?? '';
    final username = email.isNotEmpty
        ? email.split('@').first
        : (displayName.isEmpty ? 'adventurer' : displayName);
    return UserEntity(
      // Mask to a positive int: hashCode can be negative, and this id is used
      // downstream as a post userId and leaderboard entry key.
      id: user.uid.hashCode & 0x7fffffff,
      username: username,
      email: email,
      firstName: parts.isNotEmpty ? parts.first : '',
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      image: user.photoURL ?? '',
    );
  }

  /// Unwraps the `Exception: <message>` prefix for display.
  String _readableError(Object error) {
    const prefix = 'Exception: ';
    final text = error.toString();
    return text.startsWith(prefix) ? text.substring(prefix.length) : text;
  }
}
