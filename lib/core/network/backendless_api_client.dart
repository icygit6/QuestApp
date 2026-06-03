import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_storage_keys.dart';
import 'network_info.dart';

/// Dio client configured for the Backendless REST API.
class BackendlessApiClient {
  BackendlessApiClient({
    required FlutterSecureStorage secureStorage,
    required NetworkInfo networkInfo,
    required String baseUrl,
    required String appId,
    required String restApiKey,
  }) : _secureStorage = secureStorage,
       _networkInfo = networkInfo,
       _baseUrl = baseUrl,
       _appId = appId,
       _restApiKey = restApiKey {
    dio = _buildDio();
  }

  final FlutterSecureStorage _secureStorage;
  final NetworkInfo _networkInfo;
  final String _baseUrl;
  final String _appId;
  final String _restApiKey;

  late final Dio dio;

  bool get hasConfig =>
      _baseUrl.isNotEmpty && _appId.isNotEmpty && _restApiKey.isNotEmpty;

  String get _endpoint => '$_baseUrl/$_appId/$_restApiKey';

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _endpoint,
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

          if (options.extra['skipAuth'] == true) {
            handler.next(options);
            return;
          }

          final token = await _secureStorage.read(
            key: AuthStorageKeys.backendlessUserToken,
          );
          if (token != null && token.isNotEmpty) {
            options.headers['user-token'] = token;
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }
}
