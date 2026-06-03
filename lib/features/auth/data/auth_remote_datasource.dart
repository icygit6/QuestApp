import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import 'user_model.dart';

class DummyAuthRemoteDataSource {
  const DummyAuthRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  /// Calls DummyJSON POST /auth/login.
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final response = await _dioClient.dummyDio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password, 'expiresInMins': 30},
      options: Options(extra: {'skipAuth': true}),
    );
    return UserModel.fromJson(response.data ?? <String, dynamic>{});
  }

  /// Calls DummyJSON POST /users/add.
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.dummyDio.post<Map<String, dynamic>>(
      '/users/add',
      data: {
        'username': username,
        'email': email,
        'password': password,
        'firstName': username,
        'lastName': 'Adventurer',
      },
    );
    final created = UserModel.fromJson(response.data ?? <String, dynamic>{});
    return UserModel(
      id: created.id,
      username: created.username,
      email: created.email,
      firstName: created.firstName,
      lastName: created.lastName,
      image: created.image,
      token:
          'registered-${created.id}-${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
