import '../../../core/errors/failures.dart';
import '../../../core/network/favqs_api_client.dart';
import 'quote_model.dart';

class QuotesRemoteDataSource {
  const QuotesRemoteDataSource(this._client);

  final FavqsApiClient _client;

  Future<List<QuoteModel>> getQuotes({String? filter, int page = 1}) async {
    _ensureApiKey();
    final queryParameters = <String, dynamic>{'page': page};
    final trimmed = filter?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      queryParameters['filter'] = trimmed;
    }
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/quotes',
      queryParameters: queryParameters,
    );
    final data = response.data ?? <String, dynamic>{};
    final quotes = (data['quotes'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>();
    return quotes.map(QuoteModel.fromJson).toList(growable: false);
  }

  Future<QuoteModel> getQuoteDetail(int id) async {
    _ensureApiKey();
    final response = await _client.dio.get<Map<String, dynamic>>('/quotes/$id');
    return QuoteModel.fromJson(response.data ?? <String, dynamic>{});
  }

  void _ensureApiKey() {
    if (!_client.hasApiKey) {
      throw const ValidationFailure(
        'Missing FAVQS_API_KEY. Pass it via --dart-define.',
      );
    }
  }
}
