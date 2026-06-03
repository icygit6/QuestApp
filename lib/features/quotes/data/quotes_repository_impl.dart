import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../domain/quote_entity.dart';
import '../domain/quote_repository.dart';
import 'quotes_remote_datasource.dart';

class QuotesRepositoryImpl implements QuoteRepository {
  const QuotesRepositoryImpl(this._remoteDataSource);

  final QuotesRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<QuoteEntity>>> getQuotes({
    String? filter,
    int page = 1,
  }) async {
    try {
      final quotes = await _remoteDataSource.getQuotes(
        filter: filter,
        page: page,
      );
      return Right(quotes);
    } catch (error) {
      if (error is Failure) {
        return Left(error);
      }
      return Left(mapDioFailure(error));
    }
  }

  @override
  Future<Either<Failure, QuoteEntity>> getQuoteDetail(int id) async {
    try {
      final quote = await _remoteDataSource.getQuoteDetail(id);
      return Right(quote);
    } catch (error) {
      if (error is Failure) {
        return Left(error);
      }
      return Left(mapDioFailure(error));
    }
  }
}
