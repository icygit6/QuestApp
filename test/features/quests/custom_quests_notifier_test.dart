import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:questboard/features/quests/data/custom_quest_local_datasource.dart';
import 'package:questboard/features/quests/data/quest_model.dart';
import 'package:questboard/features/quests/data/quest_repository_impl.dart';
import 'package:questboard/features/quests/domain/quest_entity.dart';
import 'package:questboard/features/quests/presentation/custom_quest_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<QuestModel> box;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('qb_custom_quest_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(QuestModelAdapter());
    }
    box = await Hive.openBox<QuestModel>('user_quests_test');
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<CustomQuestsNotifier> buildNotifier([
    Map<String, Object> prefsValues = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    return CustomQuestsNotifier(
      dataSource: CustomQuestLocalDataSource(box),
      preferences: prefs,
    );
  }

  test('create adds a persisted custom quest with derived xp', () async {
    final notifier = await buildNotifier();
    final created = await notifier.create(
      title: 'Slay the dragon',
      description: '',
      difficulty: QuestDifficulty.hard,
      category: QuestCategory.combat,
      assignedTo: 1,
    );

    expect(created.isCustom, isTrue);
    expect(created.xpReward, QuestDifficulty.hard.xpReward);
    expect(notifier.state, hasLength(1));
    expect(notifier.state.first.title, 'Slay the dragon');
    expect(notifier.state.first.isCompleted, isFalse);
    expect(box.values, hasLength(1));
  });

  test('completion is derived from the shared completed-ids store', () async {
    final seed = await (await buildNotifier()).create(
      title: 'Gather herbs',
      description: '',
      difficulty: QuestDifficulty.easy,
      category: QuestCategory.crafting,
      assignedTo: 1,
    );

    final notifier = await buildNotifier({
      QuestRepositoryImpl.completedQuestIdsKey: <String>['${seed.id}'],
    });
    expect(notifier.state.single.isCompleted, isTrue);
  });

  test('delete removes the quest from state and storage', () async {
    final notifier = await buildNotifier();
    final created = await notifier.create(
      title: 'Temp quest',
      description: '',
      difficulty: QuestDifficulty.medium,
      category: QuestCategory.social,
      assignedTo: 1,
    );
    expect(notifier.state, hasLength(1));

    await notifier.delete(created.id);
    expect(notifier.state, isEmpty);
    expect(box.values, isEmpty);
  });
}
