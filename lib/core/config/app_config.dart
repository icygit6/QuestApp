import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for external APIs loaded from .env or --dart-define.
abstract final class AppConfig {
  static String get favqsApiKey => _get('FAVQS_API_KEY');

  static String get backendlessAppId => _get('BACKENDLESS_APP_ID');

  static String get backendlessRestApiKey => _get('BACKENDLESS_REST_API_KEY');

  static String get backendlessBaseUrl =>
      _get('BACKENDLESS_BASE_URL', fallback: 'https://api.backendless.com');

  static String _get(String key, {String fallback = ''}) {
    final fromDotenv = dotenv.env[key];
    if (fromDotenv != null && fromDotenv.isNotEmpty) {
      return fromDotenv;
    }
    return String.fromEnvironment(key, defaultValue: fallback);
  }
}
