import '../../../core/errors/failures.dart';
import 'quote_entity.dart';

abstract interface class QuoteRepository {
  Future<Either<Failure, List<QuoteEntity>>> getQuotes({
    String? filter,
    int page,
  });

  Future<Either<Failure, QuoteEntity>> getQuoteDetail(int id);
}
