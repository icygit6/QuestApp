import 'package:flutter_test/flutter_test.dart';
import 'package:questboard/features/quests/domain/quest_entity.dart';

void main() {
  group('QuestEntity.isCustom', () {
    QuestEntity questWithId(int id) => QuestEntity(
          id: id,
          title: 'Quest',
          description: 'desc',
          isCompleted: false,
          assignedTo: 1,
          difficulty: QuestDifficulty.easy,
          category: QuestCategory.combat,
          xpReward: 50,
        );

    test('API quests (small ids) are not custom', () {
      expect(questWithId(1).isCustom, isFalse);
      expect(questWithId(250).isCustom, isFalse);
      expect(questWithId(kCustomQuestIdBase - 1).isCustom, isFalse);
    });

    test('ids at or above the base are custom', () {
      expect(questWithId(kCustomQuestIdBase).isCustom, isTrue);
      // A creation-timestamp id is far above the base.
      expect(questWithId(DateTime.now().millisecondsSinceEpoch).isCustom,
          isTrue);
    });
  });
}
