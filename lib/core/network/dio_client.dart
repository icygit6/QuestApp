import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/failures.dart';
import 'network_info.dart';

/// Configured Dio clients for DummyJSON and JSONPlaceholder.
class DioClient {
  DioClient({
    required FlutterSecureStorage secureStorage,
    required NetworkInfo networkInfo,
  }) : _secureStorage = secureStorage,
       _networkInfo = networkInfo {
    dummyDio = _buildDio('https://dummyjson.com');
    jsonPlaceholderDio = _buildDio('https://jsonplaceholder.typicode.com');
  }

  static const authTokenKey = 'auth_token';
  static const refreshTokenKey = 'refresh_token';
  static const userIdKey = 'user_id';

  final FlutterSecureStorage _secureStorage;
  final NetworkInfo _networkInfo;

  late final Dio dummyDio;
  late final Dio jsonPlaceholderDio;

  Dio _buildDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
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

          final token = await _secureStorage.read(key: authTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final canRefresh =
              status == 401 &&
              baseUrl.contains('dummyjson.com') &&
              error.requestOptions.extra['authRetried'] != true;

          if (canRefresh && await _tryRefreshToken(dio)) {
            final retried = await _retryWithFreshToken(
              error.requestOptions,
              dio,
            );
            handler.resolve(retried);
            return;
          }

          final retried = await _retryTransient(error, dio);
          if (retried != null) {
            handler.resolve(retried);
            return;
          }

          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: false,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }

    return dio;
  }

  Future<Response<dynamic>> _retryWithFreshToken(
    RequestOptions options,
    Dio dio,
  ) async {
    final token = await _secureStorage.read(key: authTokenKey);
    options.extra['authRetried'] = true;
    options.headers['Authorization'] = 'Bearer $token';
    return dio.fetch<dynamic>(options);
  }

  Future<bool> _tryRefreshToken(Dio dio) async {
    final refreshToken = await _secureStorage.read(key: refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await Dio().post<Map<String, dynamic>>(
        'https://dummyjson.com/auth/refresh',
        data: {'refreshToken': refreshToken, 'expiresInMins': 30},
      );
      final data = response.data ?? <String, dynamic>{};
      final token = (data['accessToken'] ?? data['token'])?.toString();
      final freshRefresh = data['refreshToken']?.toString();
      if (token == null || token.isEmpty) {
        return false;
      }
      await _secureStorage.write(key: authTokenKey, value: token);
      if (freshRefresh != null && freshRefresh.isNotEmpty) {
        await _secureStorage.write(key: refreshTokenKey, value: freshRefresh);
      }
      return true;
    } on DioException {
      await _secureStorage.delete(key: authTokenKey);
      await _secureStorage.delete(key: refreshTokenKey);
      return false;
    }
  }

  Future<Response<dynamic>?> _retryTransient(
    DioException error,
    Dio dio,
  ) async {
    if (!_isTransient(error)) {
      return null;
    }
    final attempts = (error.requestOptions.extra['retryCount'] as int?) ?? 0;
    if (attempts >= 3) {
      return null;
    }
    error.requestOptions.extra['retryCount'] = attempts + 1;
    await Future<void>.delayed(Duration(milliseconds: 250 * (attempts + 1)));
    return dio.fetch<dynamic>(error.requestOptions);
  }

  bool _isTransient(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse => (error.response?.statusCode ?? 0) >= 500,
      _ => false,
    };
  }
}

/// Converts Dio failures into domain failures.
Failure mapDioFailure(Object error) {
  if (error is DioException) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => const TimeoutFailure(),
      DioExceptionType.connectionError => const NetworkFailure(),
      DioExceptionType.badResponse => switch (error.response?.statusCode) {
        401 => const AuthFailure(),
        404 => const NotFoundFailure(),
        500 => const ServerFailure(),
        _ => ServerFailure(
          _extractMessage(error.response?.data) ??
              'The realm rejected this request.',
        ),
      },
      _ => const UnknownFailure(),
    };
  }
  return UnknownFailure(error.toString());
}

String? _extractMessage(Object? data) {
  if (data is Map<String, dynamic>) {
    return (data['message'] ?? data['error'])?.toString();
  }
  return null;
}
