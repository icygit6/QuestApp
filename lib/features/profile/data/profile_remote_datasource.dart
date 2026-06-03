import '../../../core/network/dio_client.dart';
import 'profile_model.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  /// Calls DummyJSON GET /users/{id}.
  Future<ProfileModel> getProfile(int userId) async {
    final response = await _dioClient.dummyDio.get<Map<String, dynamic>>(
      '/users/$userId',
    );
    return ProfileModel.fromJson(response.data ?? <String, dynamic>{});
  }
}
