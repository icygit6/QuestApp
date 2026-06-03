import 'package:hive/hive.dart';

import 'quest_model.dart';

class QuestLocalDataSource {
  const QuestLocalDataSource(this._box);

  final Box<QuestModel> _box;

  /// Saves fetched quests by id.
  Future<void> cacheQuests(List<QuestModel> quests) async {
    final entries = {for (final quest in quests) quest.id: quest};
    await _box.putAll(entries);
  }

  /// Reads cached quests ordered by id.
  Future<List<QuestModel>> getCachedQuests() async {
    final quests = _box.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    return quests;
  }

  /// Updates a single cached quest.
  Future<void> upsertQuest(QuestModel quest) => _box.put(quest.id, quest);

  /// Clears locally cached quests and completion state.
  Future<void> clearCache() => _box.clear();
}
