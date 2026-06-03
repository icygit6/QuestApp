import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/auth_storage_keys.dart';
import '../domain/auth_provider_type.dart';
import 'user_model.dart';

class AuthLocalDataSource {
  const AuthLocalDataSource({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences preferences,
  }) : _secureStorage = secureStorage,
       _preferences = preferences;

  static const _userJsonKey = 'auth_user_json';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _preferences;

  /// Persists token and compact user profile.
  Future<void> saveUser(UserModel user) async {
    await _clearTokens();
    await _persistToken(user);
    await _secureStorage.write(
      key: DioClient.userIdKey,
      value: user.id.toString(),
    );
    await _preferences.setString(_userJsonKey, jsonEncode(user.toJson()));
  }

  /// Returns the persisted user when auth token exists.
  Future<UserModel?> restoreUser() async {
    final rawUser = _preferences.getString(_userJsonKey);
    if (rawUser == null) {
      return null;
    }
    final json = jsonDecode(rawUser) as Map<String, dynamic>;
    final user = UserModel.fromJson(json);
    final token = await _readToken(user.provider);
    if (token == null || token.isEmpty) {
      return null;
    }
    return UserModel(
      id: user.id,
      username: user.username,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      image: user.image,
      token: token,
      refreshToken: user.provider == AuthProviderType.dummy
          ? await _secureStorage.read(key: DioClient.refreshTokenKey)
          : null,
      provider: user.provider,
    );
  }

  /// Clears persisted credentials and user profile.
  Future<void> clear() async {
    await _clearTokens();
    await _secureStorage.delete(key: DioClient.userIdKey);
    await _preferences.remove(_userJsonKey);
  }

  Future<void> _persistToken(UserModel user) async {
    final token = user.token;
    if (token == null || token.isEmpty) {
      return;
    }
    switch (user.provider) {
      case AuthProviderType.dummy:
        await _secureStorage.write(key: DioClient.authTokenKey, value: token);
        if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
          await _secureStorage.write(
            key: DioClient.refreshTokenKey,
            value: user.refreshToken,
          );
        }
      case AuthProviderType.favqs:
        await _secureStorage.write(
          key: AuthStorageKeys.favqsUserToken,
          value: token,
        );
      case AuthProviderType.backendless:
        await _secureStorage.write(
          key: AuthStorageKeys.backendlessUserToken,
          value: token,
        );
    }
  }

  Future<String?> _readToken(AuthProviderType provider) {
    return switch (provider) {
      AuthProviderType.dummy => _secureStorage.read(
        key: DioClient.authTokenKey,
      ),
      AuthProviderType.favqs => _secureStorage.read(
        key: AuthStorageKeys.favqsUserToken,
      ),
      AuthProviderType.backendless => _secureStorage.read(
        key: AuthStorageKeys.backendlessUserToken,
      ),
    };
  }

  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: DioClient.authTokenKey);
    await _secureStorage.delete(key: DioClient.refreshTokenKey);
    await _secureStorage.delete(key: AuthStorageKeys.favqsUserToken);
    await _secureStorage.delete(key: AuthStorageKeys.backendlessUserToken);
  }
}
