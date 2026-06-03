import 'package:hive/hive.dart';

import '../domain/achievement.dart';

class AchievementService {
  const AchievementService(this._box);

  final Box<Achievement> _box;

  static const defaults = [
    Achievement(
      id: 'first_quest',
      title: 'First Quest',
      description: 'Complete 1 quest.',
      isUnlocked: false,
    ),
    Achievement(
      id: 'on_a_roll',
      title: 'On a Roll',
      description: 'Complete 5 quests in one session.',
      isUnlocked: false,
    ),
    Achievement(
      id: 'week_warrior',
      title: 'Week Warrior',
      description: 'Reach a 7-day streak.',
      isUnlocked: false,
    ),
    Achievement(
      id: 'century',
      title: 'Century',
      description: 'Earn 100 total XP.',
      isUnlocked: false,
    ),
    Achievement(
      id: 'explorer',
      title: 'Explorer',
      description: 'Complete quests in all 4 categories.',
      isUnlocked: false,
    ),
    Achievement(
      id: 'completionist',
      title: 'Completionist',
      description: 'Complete 20 quests total.',
      isUnlocked: false,
    ),
  ];

  /// Ensures all achievement definitions exist locally.
  Future<List<Achievement>> load() async {
    for (final achievement in defaults) {
      if (!_box.containsKey(achievement.id)) {
        await _box.put(achievement.id, achievement);
      }
    }
    return _ordered();
  }

  /// Unlocks achievements that satisfy the provided predicate.
  Future<List<Achievement>> unlockWhere(
    bool Function(Achievement achievement) shouldUnlock,
  ) async {
    final now = DateTime.now();
    final unlocked = <Achievement>[];
    for (final achievement in _ordered()) {
      if (!achievement.isUnlocked && shouldUnlock(achievement)) {
        final next = achievement.unlock(now);
        await _box.put(next.id, next);
        unlocked.add(next);
      }
    }
    return unlocked;
  }

  /// Resets all achievements to locked.
  Future<void> reset() async {
    await _box.clear();
    await load();
  }

  List<Achievement> _ordered() {
    return [
      for (final achievement in defaults)
        _box.get(achievement.id) ?? achievement,
    ];
  }
}
