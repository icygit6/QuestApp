import 'package:hive/hive.dart';

import 'quest_model.dart';

/// Stores quests the user creates, separate from the API quest cache (`quests`
/// box) so an API refresh never wipes them. Reuses the [QuestModel] Hive
/// adapter (`typeId = 1`); a box can share an adapter type with another box.
///
/// This box only persists the quest *definition* (title, difficulty, ...).
/// Completion state lives in SharedPreferences alongside API quests, so a
/// custom quest is marked complete through exactly the same path.
class CustomQuestLocalDataSource {
  const CustomQuestLocalDataSource(this._box);

  final Box<QuestModel> _box;

  /// All custom quests, newest first (ids are creation timestamps).
  List<QuestModel> getAll() {
    final quests = _box.values.toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return quests;
  }

  // Keys are the stringified id: Hive caps *integer* keys at 0xFFFFFFFF, but a
  // creation-timestamp id (~1.7e12) exceeds that. Stringifying sidesteps the
  // limit while the full id is preserved inside the stored model.
  Future<void> upsert(QuestModel quest) => _box.put(quest.id.toString(), quest);

  Future<void> delete(int id) => _box.delete(id.toString());
}
