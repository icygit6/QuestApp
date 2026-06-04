import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../data/custom_quest_local_datasource.dart';
import '../data/quest_model.dart';
import '../data/quest_repository_impl.dart';
import '../domain/quest_entity.dart';

final customQuestBoxProvider = Provider<Box<QuestModel>>(
  (ref) => Hive.box<QuestModel>('user_quests'),
);

final customQuestLocalDataSourceProvider = Provider<CustomQuestLocalDataSource>(
  (ref) => CustomQuestLocalDataSource(ref.watch(customQuestBoxProvider)),
);

/// Exposes the user's locally-created quests, with completion derived from the
/// same SharedPreferences store as API quests (single source of truth).
final customQuestsProvider =
    StateNotifierProvider<CustomQuestsNotifier, List<QuestEntity>>((ref) {
      return CustomQuestsNotifier(
        dataSource: ref.watch(customQuestLocalDataSourceProvider),
        preferences: ref.watch(sharedPreferencesProvider),
      );
    });

class CustomQuestsNotifier extends StateNotifier<List<QuestEntity>> {
  CustomQuestsNotifier({
    required CustomQuestLocalDataSource dataSource,
    required SharedPreferences preferences,
  }) : _dataSource = dataSource,
       _preferences = preferences,
       super(const <QuestEntity>[]) {
    state = _build();
  }

  final CustomQuestLocalDataSource _dataSource;
  final SharedPreferences _preferences;

  List<QuestEntity> _build() {
    final completedIds = _completedIds();
    return _dataSource
        .getAll()
        .map(
          (quest) =>
              quest.copyWith(isCompleted: completedIds.contains(quest.id)),
        )
        .toList(growable: false);
  }

  Set<int> _completedIds() {
    return (_preferences.getStringList(
              QuestRepositoryImpl.completedQuestIdsKey,
            ) ??
            const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  Future<QuestEntity> create({
    required String title,
    required String description,
    required QuestDifficulty difficulty,
    required QuestCategory category,
    required int assignedTo,
  }) async {
    final trimmedDescription = description.trim();
    final quest = QuestModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title.trim(),
      description: trimmedDescription.isEmpty
          ? 'A custom ${difficulty.label.toLowerCase()} '
                '${category.label.toLowerCase()} quest.'
          : trimmedDescription,
      isCompleted: false,
      assignedTo: assignedTo,
      difficulty: difficulty,
      category: category,
      xpReward: difficulty.xpReward,
    );
    await _dataSource.upsert(quest);
    state = _build();
    return quest;
  }

  /// Persists an edited quest. `xpReward` is re-derived from difficulty so it
  /// stays consistent when the difficulty changes.
  Future<void> update(QuestEntity quest) async {
    final synced = quest.copyWith(xpReward: quest.difficulty.xpReward);
    await _dataSource.upsert(QuestModel.fromEntity(synced));
    state = _build();
  }

  Future<void> delete(int id) async {
    await _dataSource.delete(id);
    state = _build();
  }
}
