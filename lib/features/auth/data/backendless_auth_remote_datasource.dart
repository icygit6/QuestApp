import 'package:dio/dio.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/backendless_api_client.dart';
import '../domain/auth_provider_type.dart';
import 'user_model.dart';

class BackendlessAuthRemoteDataSource {
  const BackendlessAuthRemoteDataSource(this._client);

  final BackendlessApiClient _client;

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    _ensureConfig();
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/users/login',
      data: {'login': username, 'password': password},
      options: Options(extra: {'skipAuth': true}),
    );

    final data = response.data ?? <String, dynamic>{};
    final token = _extractToken(data, response.headers);
    if (token == null || token.isEmpty) {
      throw const AuthFailure('Backendless login failed.');
    }
    return _mapUser(data, token, fallbackName: username);
  }

  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _ensureConfig();
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/users/register',
      data: {'email': email, 'password': password, 'name': username},
      options: Options(extra: {'skipAuth': true}),
    );
    final data = response.data ?? <String, dynamic>{};
    return _mapUser(data, null, fallbackName: username);
  }

  UserModel _mapUser(
    Map<String, dynamic> data,
    String? token, {
    required String fallbackName,
  }) {
    final objectId = data['objectId']?.toString() ?? '';
    final name = (data['name'] ?? fallbackName).toString();
    final email = (data['email'] ?? '').toString();
    final nameParts = name.trim().isEmpty ? <String>[] : name.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : name;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final id = objectId.isNotEmpty
        ? objectId.hashCode.abs()
        : DateTime.now().millisecondsSinceEpoch;

    return UserModel(
      id: id,
      username: name,
      email: email,
      firstName: firstName,
      lastName: lastName,
      image: '',
      token: token,
      provider: AuthProviderType.backendless,
    );
  }

  String? _extractToken(Map<String, dynamic> data, Headers headers) {
    return headers.value('user-token') ??
        headers.value('User-Token') ??
        data['user-token']?.toString() ??
        data['userToken']?.toString() ??
        data['user_token']?.toString();
  }

  void _ensureConfig() {
    if (!_client.hasConfig) {
      throw const ValidationFailure(
        'Missing Backendless keys. Pass APP_ID, REST_API_KEY, BASE_URL.',
      );
    }
  }
}
