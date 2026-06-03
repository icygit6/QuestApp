import 'package:dio/dio.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/favqs_api_client.dart';
import '../domain/auth_provider_type.dart';
import 'user_model.dart';

class FavqsAuthRemoteDataSource {
  const FavqsAuthRemoteDataSource(this._client);

  final FavqsApiClient _client;

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    if (!_client.hasApiKey) {
      throw const ValidationFailure(
        'Missing FAVQS_API_KEY. Pass it via --dart-define.',
      );
    }

    final response = await _client.dio.post<Map<String, dynamic>>(
      '/session',
      data: {
        'user': {'login': username, 'password': password},
      },
      options: Options(extra: {'skipAuth': true}),
    );

    final data = response.data ?? <String, dynamic>{};
    final token = _extractToken(data, response.headers);
    if (token == null || token.isEmpty) {
      throw const AuthFailure('FavQs login failed.');
    }

    final login = (data['login'] ?? data['user']?['login'] ?? username)
        .toString();
    final email = (data['email'] ?? data['user']?['email'] ?? '').toString();
    final name = (data['name'] ?? '').toString().trim();
    final nameParts = name.isEmpty ? <String>[] : name.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : login;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return UserModel(
      id: login.hashCode.abs(),
      username: login,
      email: email,
      firstName: firstName,
      lastName: lastName,
      image: '',
      token: token,
      provider: AuthProviderType.favqs,
    );
  }

  String? _extractToken(Map<String, dynamic> data, Headers headers) {
    return headers.value('User-Token') ??
        headers.value('user-token') ??
        data['User-Token']?.toString() ??
        data['user-token']?.toString() ??
        data['userToken']?.toString() ??
        data['user_token']?.toString();
  }
}
