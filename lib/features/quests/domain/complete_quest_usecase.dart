import '../../../core/errors/failures.dart';
import 'quest_entity.dart';
import 'quest_repository.dart';

class CompleteQuestUseCase {
  const CompleteQuestUseCase(this._repository);

  final QuestRepository _repository;

  /// Completes a quest and returns the updated entity.
  Future<Either<Failure, QuestEntity>> call(QuestEntity quest) {
    return _repository.completeQuest(quest);
  }
}
