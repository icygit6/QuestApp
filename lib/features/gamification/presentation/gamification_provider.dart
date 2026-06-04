import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/xp_calculator.dart';
import '../../leaderboard/presentation/leaderboard_provider.dart';
import '../../quests/data/quest_model.dart';
import '../../quests/data/quest_repository_impl.dart';
import '../../quests/domain/quest_entity.dart';
import '../../quests/presentation/quest_provider.dart';
import '../data/achievement_service.dart';
import '../domain/achievement.dart';
import '../domain/daily_record.dart';

final achievementBoxProvider = Provider<Box<Achievement>>(
  (ref) => Hive.box<Achievement>('achievements'),
);

final dailyBoxProvider = Provider<Box<DailyRecord>>(
  (ref) => Hive.box<DailyRecord>('daily'),
);

final achievementServiceProvider = Provider<AchievementService>(
  (ref) => AchievementService(ref.watch(achievementBoxProvider)),
);

final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
      return GamificationNotifier(
        ref: ref,
        preferences: ref.watch(sharedPreferencesProvider),
        dailyBox: ref.watch(dailyBoxProvider),
        achievementService: ref.watch(achievementServiceProvider),
      )..load();
    });

class GamificationState {
  const GamificationState({
    required this.xp,
    required this.level,
    required this.streak,
    required this.totalXpEarned,
    required this.totalQuestsCompleted,
    required this.sessionCompleted,
    required this.categoryCounts,
    required this.achievements,
    required this.isLoading,
  });

  factory GamificationState.initial() {
    return const GamificationState(
      xp: 0,
      level: 1,
      streak: 0,
      totalXpEarned: 0,
      totalQuestsCompleted: 0,
      sessionCompleted: 0,
      categoryCounts: {},
      achievements: [],
      isLoading: true,
    );
  }

  final int xp;
  final int level;
  final int streak;
  final int totalXpEarned;
  final int totalQuestsCompleted;
  final int sessionCompleted;
  final Map<String, int> categoryCounts;
  final List<Achievement> achievements;
  final bool isLoading;

  int get nextLevelXp => XpCalculator.xpForNextLevel(level);

  GamificationState copyWith({
    int? xp,
    int? level,
    int? streak,
    int? totalXpEarned,
    int? totalQuestsCompleted,
    int? sessionCompleted,
    Map<String, int>? categoryCounts,
    List<Achievement>? achievements,
    bool? isLoading,
  }) {
    return GamificationState(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      totalQuestsCompleted: totalQuestsCompleted ?? this.totalQuestsCompleted,
      sessionCompleted: sessionCompleted ?? this.sessionCompleted,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      achievements: achievements ?? this.achievements,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GamificationEvent {
  const GamificationEvent({
    required this.xpGained,
    required this.leveledUp,
    required this.newLevel,
    required this.unlockedAchievements,
  });

  final int xpGained;
  final bool leveledUp;
  final int newLevel;
  final List<Achievement> unlockedAchievements;
}

class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier({
    required Ref ref,
    required this.preferences,
    required this.dailyBox,
    required this.achievementService,
  }) : _ref = ref,
       super(GamificationState.initial());

  static const _currentXpKey = 'current_xp';
  static const _currentLevelKey = 'current_level';
  static const _totalXpKey = 'total_xp_earned';
  static const _totalQuestsKey = 'total_quests_completed';
  static const _lastActiveKey = 'last_active_date';
  static const _currentStreakKey = 'current_streak';
  static const _categoryCountsKey = 'quests_per_category';

  final SharedPreferences preferences;
  final Box<DailyRecord> dailyBox;
  final AchievementService achievementService;
  final Ref _ref;

  /// Loads XP, streak, category counts, and achievements from local storage.
  Future<void> load() async {
    final achievements = await achievementService.load();
    state = state.copyWith(
      xp: preferences.getInt(_currentXpKey) ?? 0,
      level: preferences.getInt(_currentLevelKey) ?? 1,
      totalXpEarned: preferences.getInt(_totalXpKey) ?? 0,
      totalQuestsCompleted: preferences.getInt(_totalQuestsKey) ?? 0,
      streak: preferences.getInt(_currentStreakKey) ?? 0,
      categoryCounts: _decodeCategoryCounts(
        preferences.getString(_categoryCountsKey),
      ),
      achievements: achievements,
      isLoading: false,
    );
  }

  /// Applies XP, streak, daily history, and achievements for a completed quest.
  Future<GamificationEvent> completeQuest(QuestEntity quest) async {
    final streak = await _updateStreak();
    final xpGained = XpCalculator.xpWithStreakBonus(quest.xpReward, streak);
    var xp = state.xp + xpGained;
    var level = state.level;
    var leveledUp = false;
    while (xp >= XpCalculator.xpForNextLevel(level)) {
      xp -= XpCalculator.xpForNextLevel(level);
      level += 1;
      leveledUp = true;
    }

    final categoryCounts = Map<String, int>.from(state.categoryCounts);
    categoryCounts.update(
      quest.category.label,
      (value) => value + 1,
      ifAbsent: () => 1,
    );

    final totalXpEarned = state.totalXpEarned + xpGained;
    final totalCompleted = state.totalQuestsCompleted + 1;
    final sessionCompleted = state.sessionCompleted + 1;

    final unlocked = await achievementService.unlockWhere((achievement) {
      return switch (achievement.id) {
        'first_quest' => totalCompleted >= 1,
        'on_a_roll' => sessionCompleted >= 5,
        'week_warrior' => streak >= 7,
        'century' => totalXpEarned >= 100,
        'explorer' => QuestCategory.values.every(
          (category) => (categoryCounts[category.label] ?? 0) > 0,
        ),
        'completionist' => totalCompleted >= 20,
        _ => false,
      };
    });

    final achievements = await achievementService.load();
    state = state.copyWith(
      xp: xp,
      level: level,
      streak: streak,
      totalXpEarned: totalXpEarned,
      totalQuestsCompleted: totalCompleted,
      sessionCompleted: sessionCompleted,
      categoryCounts: categoryCounts,
      achievements: achievements,
    );
    await _persist();
    // leaderboardProvider already auto-invalidates because it watches
    // gamificationProvider — the explicit invalidate is only a best-effort
    // hint and must not propagate failures.
    try {
      _ref.invalidate(leaderboardProvider);
    } catch (_) {}

    return GamificationEvent(
      xpGained: xpGained,
      leveledUp: leveledUp,
      newLevel: level,
      unlockedAchievements: unlocked,
    );
  }

  /// Clears all local gamification progress.
  Future<void> resetProgress() => resetAllProgress();

  /// Clears all local progress, quest completion truth, and dependent state.
  Future<void> resetAllProgress() async {
    await preferences.remove(_currentXpKey);
    await preferences.remove(_currentLevelKey);
    await preferences.remove(_totalXpKey);
    await preferences.remove(_totalQuestsKey);
    await preferences.remove(_lastActiveKey);
    await preferences.remove(_currentStreakKey);
    await preferences.remove(_categoryCountsKey);
    await preferences.remove(QuestRepositoryImpl.completedQuestIdsKey);
    await preferences.remove(QuestRepositoryImpl.completionTimesKey);
    await preferences.remove(QuestRepositoryImpl.cacheVersionKey);
    await Hive.box<QuestModel>('quests').clear();
    await dailyBox.clear();
    await achievementService.reset();
    state = GamificationState.initial().copyWith(
      achievements: await achievementService.load(),
      isLoading: false,
    );
    _ref.invalidate(questsProvider);
    _ref.invalidate(leaderboardProvider);
  }

  Future<int> _updateStreak() async {
    final now = DateTime.now();
    final todayKey = DateFormatter.dayKey(now);
    final dailyRecord = dailyBox.get(todayKey);
    await dailyBox.put(
      todayKey,
      dailyRecord?.increment() ??
          DailyRecord(dateKey: todayKey, completedCount: 1),
    );

    final lastRaw = preferences.getString(_lastActiveKey);
    final previousStreak = preferences.getInt(_currentStreakKey) ?? 0;
    var streak = previousStreak;
    if (lastRaw == null) {
      streak = 1;
    } else {
      final last = DateTime.tryParse(lastRaw);
      if (last == null) {
        streak = 1;
      } else if (DateFormatter.isSameDay(last, now)) {
        streak = previousStreak == 0 ? 1 : previousStreak;
      } else if (DateFormatter.isYesterday(last, now)) {
        streak = previousStreak + 1;
      } else {
        streak = 1;
      }
    }
    await preferences.setString(_lastActiveKey, now.toIso8601String());
    await preferences.setInt(_currentStreakKey, streak);
    return streak;
  }

  Future<void> _persist() async {
    await preferences.setInt(_currentXpKey, state.xp);
    await preferences.setInt(_currentLevelKey, state.level);
    await preferences.setInt(_totalXpKey, state.totalXpEarned);
    await preferences.setInt(_totalQuestsKey, state.totalQuestsCompleted);
    await preferences.setInt(_currentStreakKey, state.streak);
    await preferences.setString(
      _categoryCountsKey,
      jsonEncode(state.categoryCounts),
    );
  }

  Map<String, int> _decodeCategoryCounts(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
  }
}
