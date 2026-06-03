import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'network/backendless_api_client.dart';
import 'network/dio_client.dart';
import 'network/favqs_api_client.dart';
import 'network/network_info.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences must be overridden.'),
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfo(ref.watch(connectivityProvider)),
);

final dioClientProvider = Provider<DioClient>(
  (ref) => DioClient(
    secureStorage: ref.watch(secureStorageProvider),
    networkInfo: ref.watch(networkInfoProvider),
  ),
);

final favqsApiClientProvider = Provider<FavqsApiClient>(
  (ref) => FavqsApiClient(
    secureStorage: ref.watch(secureStorageProvider),
    networkInfo: ref.watch(networkInfoProvider),
    apiKey: AppConfig.favqsApiKey,
  ),
);

final backendlessApiClientProvider = Provider<BackendlessApiClient>(
  (ref) => BackendlessApiClient(
    secureStorage: ref.watch(secureStorageProvider),
    networkInfo: ref.watch(networkInfoProvider),
    baseUrl: AppConfig.backendlessBaseUrl,
    appId: AppConfig.backendlessAppId,
    restApiKey: AppConfig.backendlessRestApiKey,
  ),
);
