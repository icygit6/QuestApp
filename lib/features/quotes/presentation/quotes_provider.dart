import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/quotes_remote_datasource.dart';
import '../data/quotes_repository_impl.dart';
import '../domain/quote_entity.dart';
import '../domain/quote_repository.dart';

final quotesRemoteDataSourceProvider = Provider<QuotesRemoteDataSource>(
  (ref) => QuotesRemoteDataSource(ref.watch(favqsApiClientProvider)),
);

final quotesRepositoryProvider = Provider<QuoteRepository>(
  (ref) => QuotesRepositoryImpl(ref.watch(quotesRemoteDataSourceProvider)),
);

final quotesProvider = StateNotifierProvider<QuotesNotifier, QuotesState>(
  (ref) =>
      QuotesNotifier(repository: ref.watch(quotesRepositoryProvider))..load(),
);

final quotesSearchProvider = StateProvider<String>((ref) => '');

final quoteDetailProvider = FutureProvider.family<QuoteEntity, int>((
  ref,
  id,
) async {
  final result = await ref.watch(quotesRepositoryProvider).getQuoteDetail(id);
  return result.fold((failure) => throw failure.message, (quote) => quote);
});

enum QuotesStatus { loading, loaded, error }

class QuotesState {
  const QuotesState({
    required this.status,
    required this.quotes,
    required this.query,
    required this.isRefreshing,
    this.message,
  });

  factory QuotesState.initial() {
    return const QuotesState(
      status: QuotesStatus.loading,
      quotes: <QuoteEntity>[],
      query: '',
      isRefreshing: false,
    );
  }

  final QuotesStatus status;
  final List<QuoteEntity> quotes;
  final String query;
  final bool isRefreshing;
  final String? message;

  QuotesState copyWith({
    QuotesStatus? status,
    List<QuoteEntity>? quotes,
    String? query,
    bool? isRefreshing,
    String? message,
  }) {
    return QuotesState(
      status: status ?? this.status,
      quotes: quotes ?? this.quotes,
      query: query ?? this.query,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      message: message,
    );
  }
}

class QuotesNotifier extends StateNotifier<QuotesState> {
  QuotesNotifier({required QuoteRepository repository})
    : _repository = repository,
      super(QuotesState.initial());

  final QuoteRepository _repository;

  Future<void> load({bool refresh = false, String? query}) async {
    final nextQuery = query ?? state.query;
    final trimmedQuery = nextQuery.trim();

    if (refresh && state.quotes.isNotEmpty) {
      state = state.copyWith(
        isRefreshing: true,
        query: nextQuery,
        message: null,
      );
    } else {
      state = state.copyWith(
        status: QuotesStatus.loading,
        quotes: refresh ? <QuoteEntity>[] : state.quotes,
        query: nextQuery,
        message: null,
        isRefreshing: false,
      );
    }

    final result = await _repository.getQuotes(
      filter: trimmedQuery.isEmpty ? null : trimmedQuery,
      page: 1,
    );

    state = result.fold(
      (failure) => state.copyWith(
        status: QuotesStatus.error,
        message: failure.message,
        isRefreshing: false,
      ),
      (quotes) => state.copyWith(
        status: QuotesStatus.loaded,
        quotes: quotes,
        isRefreshing: false,
      ),
    );
  }
}
