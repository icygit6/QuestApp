import '../../../core/errors/failures.dart';
import 'quest_entity.dart';

abstract interface class QuestRepository {
  /// Loads paged quests, using local Hive cache when remote fetch fails.
  Future<Either<Failure, List<QuestEntity>>> getQuests({
    required int limit,
    required int skip,
    int? userId,
  });

  /// Marks a quest complete remotely and updates local cache.
  Future<Either<Failure, QuestEntity>> completeQuest(QuestEntity quest);

  /// Returns cached quests without network access.
  Future<List<QuestEntity>> getCachedQuests();
}
