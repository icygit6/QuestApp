import '../../../core/errors/failures.dart';
import 'quest_entity.dart';
import 'quest_repository.dart';

class GetQuestsUseCase {
  const GetQuestsUseCase(this._repository);

  final QuestRepository _repository;

  /// Fetches a page of quests.
  Future<Either<Failure, List<QuestEntity>>> call({
    required int limit,
    required int skip,
    int? userId,
  }) {
    return _repository.getQuests(limit: limit, skip: skip, userId: userId);
  }
}
