import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around Google Sign-In + Firebase Authentication.
///
/// Kept framework-agnostic (no Flutter widgets) so it can be driven from a
/// Riverpod notifier — see `../features/auth/presentation/auth_provider.dart`.
///
/// Written against **google_sign_in 7.x**, whose API differs from 6.x:
///   * [GoogleSignIn] is a singleton ([GoogleSignIn.instance]) that must be
///     [GoogleSignIn.initialize]d exactly once before use.
///   * The interactive flow is [GoogleSignIn.authenticate] (not `signIn`), which
///     returns a non-null account or throws a [GoogleSignInException].
///   * Tokens come back synchronously and expose only an `idToken`, which is all
///     Firebase needs to build a credential.
///
/// On Android no `serverClientId` is passed: the plugin reads the web OAuth
/// client (`client_type: 3`) straight from `google-services.json`.
class GoogleAuthService {
  /// [FirebaseAuth] is injectable to keep the class unit-testable. The Google
  /// singleton cannot be injected, so it is referenced directly.
  GoogleAuthService({FirebaseAuth? firebaseAuth}) : _injectedAuth = firebaseAuth;

  final FirebaseAuth? _injectedAuth;

  /// Caches the one-shot [GoogleSignIn.initialize] call. Reset to null on
  /// failure so a later attempt can retry.
  Future<void>? _initialization;

  /// Resolve [FirebaseAuth] lazily.
  ///
  /// If Firebase failed to initialise (e.g. a misconfigured
  /// `google-services.json`), `FirebaseAuth.instance` throws. Deferring that
  /// access out of the constructor guarantees that simply *creating* this
  /// service never crashes the app — the error is instead caught inside each
  /// method and surfaced to the UI as a readable message.
  FirebaseAuth get _firebaseAuth => _injectedAuth ?? FirebaseAuth.instance;

  /// Initialises the Google singleton exactly once (v7 requirement).
  Future<void> _ensureInitialized() async {
    try {
      await (_initialization ??= GoogleSignIn.instance.initialize());
    } catch (error) {
      _initialization = null; // Allow a retry on the next attempt.
      rethrow;
    }
  }

  /// The currently signed-in Firebase user, or `null` if nobody is signed in
  /// (or if Firebase is not ready). Firebase persists this across restarts, so
  /// it can be used to restore a session on startup — note this does not need
  /// the Google singleton to be initialised.
  User? getCurrentUser() {
    try {
      return _firebaseAuth.currentUser;
    } catch (error, stack) {
      debugPrint('[GoogleAuthService] getCurrentUser failed (Firebase not '
          'initialized?): $error');
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }

  /// Emits on every Firebase sign-in / sign-out, for reactive listeners.
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  /// Runs the interactive Google Sign-In flow and signs the user into Firebase.
  ///
  /// Returns the resulting [UserCredential] on success, or `null` when the user
  /// dismisses the flow (cancel / interrupt — not an error).
  ///
  /// Throws an [Exception] carrying a human-readable message on any genuine
  /// failure (misconfigured OAuth client, missing SHA-1, network drop,
  /// uninitialised Firebase, ...), so the caller can show it to the user.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      // Some platforms (e.g. web) provide their own sign-in UI and don't
      // support the programmatic flow. Android does.
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw Exception('Google Sign-In is not supported on this platform.');
      }

      // 1. Trigger the account picker. Throws GoogleSignInException on cancel.
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate(scopeHint: const <String>['email']);

      // 2. v7 returns tokens synchronously; Firebase only needs the idToken.
      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        throw Exception(
          'Google did not return an ID token. Verify the web OAuth client in '
          'google-services.json.',
        );
      }

      // 3. Wrap the Google idToken in a Firebase credential and sign in.
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      debugPrint(
        '[GoogleAuthService] Signed in as ${userCredential.user?.email}',
      );
      return userCredential;
    } on GoogleSignInException catch (error, stack) {
      // Cancel / transient interrupt: not an error — return to the form quietly.
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        debugPrint('[GoogleAuthService] Sign-in dismissed: ${error.code}');
        return null;
      }
      debugPrint(
        '[GoogleAuthService] GoogleSignInException: '
        '${error.code} — ${error.description}',
      );
      debugPrintStack(stackTrace: stack);
      throw Exception(_googleErrorMessage(error));
    } on FirebaseAuthException catch (error, stack) {
      debugPrint(
        '[GoogleAuthService] FirebaseAuthException: '
        '${error.code} — ${error.message}',
      );
      debugPrintStack(stackTrace: stack);
      throw Exception(_firebaseErrorMessage(error));
    } catch (error, stack) {
      debugPrint('[GoogleAuthService] Sign-in failed: $error');
      debugPrintStack(stackTrace: stack);
      // Re-surface our own already-friendly Exceptions as-is.
      if (error is Exception) rethrow;
      throw Exception('Google sign-in failed. Please try again.');
    }
  }

  /// Signs out of BOTH Firebase and Google.
  ///
  /// Signing out of Google as well forces the account picker to reappear on the
  /// next sign-in instead of silently re-using the last account. Failures are
  /// logged and swallowed because a failed sign-out should never block the UI.
  Future<void> signOut() async {
    try {
      // signOut() is a Google-singleton method, so it needs initialize() first.
      await _ensureInitialized();
      await Future.wait(<Future<void>>[
        _firebaseAuth.signOut(),
        GoogleSignIn.instance.signOut(),
      ]);
      debugPrint('[GoogleAuthService] Signed out of Firebase + Google.');
    } catch (error, stack) {
      debugPrint('[GoogleAuthService] Sign-out failed: $error');
      debugPrintStack(stackTrace: stack);
    }
  }

  /// Maps Google sign-in error codes to friendly, user-facing copy.
  String _googleErrorMessage(GoogleSignInException error) {
    return switch (error.code) {
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Google Sign-In is misconfigured. Check the SHA-1 fingerprint and that '
            'google-services.json contains a web OAuth client.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'Google Sign-In could not be displayed. Please try again.',
      GoogleSignInExceptionCode.userMismatch =>
        'A different Google account is already signed in.',
      _ => error.description ?? 'Google sign-in failed. Please try again.',
    };
  }

  /// Maps Firebase error codes to friendly, user-facing copy.
  String _firebaseErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'account-exists-with-different-credential' =>
        'An account already exists with a different sign-in method.',
      'invalid-credential' => 'The Google credential is invalid or expired.',
      'user-disabled' => 'This account has been disabled.',
      'network-request-failed' =>
        'Network error. Please check your connection.',
      _ => error.message ?? 'Authentication failed. Please try again.',
    };
  }
}
