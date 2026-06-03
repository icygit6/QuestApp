import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_storage_keys.dart';
import 'network_info.dart';

/// Dio client configured for the FavQs API.
class FavqsApiClient {
  FavqsApiClient({
    required FlutterSecureStorage secureStorage,
    required NetworkInfo networkInfo,
    required String apiKey,
  }) : _secureStorage = secureStorage,
       _networkInfo = networkInfo,
       _apiKey = apiKey {
    dio = _buildDio();
  }

  static const _baseUrl = 'https://favqs.com/api';

  final FlutterSecureStorage _secureStorage;
  final NetworkInfo _networkInfo;
  final String _apiKey;

  late final Dio dio;

  bool get hasApiKey => _apiKey.isNotEmpty;

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!await _networkInfo.isConnected) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: 'No internet connection.',
              ),
            );
            return;
          }

          if (_apiKey.isNotEmpty) {
            options.headers['Authorization'] = 'Token token="$_apiKey"';
          }

          final userToken = await _secureStorage.read(
            key: AuthStorageKeys.favqsUserToken,
          );
          if (userToken != null && userToken.isNotEmpty) {
            options.headers['User-Token'] = userToken;
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }
}
