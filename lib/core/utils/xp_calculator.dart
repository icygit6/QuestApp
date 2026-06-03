import 'dart:math';

/// XP and leveling rules for QuestBoard.
abstract final class XpCalculator {
  static int xpForNextLevel(int level) {
    return (100 * pow(level, 1.5)).round();
  }

  static int xpWithStreakBonus(int baseXp, int streak) {
    final bonusPercent = min(streak, 5) * 0.10;
    return (baseXp * (1 + bonusPercent)).round();
  }

  static String titleForLevel(int level) {
    if (level <= 5) {
      return 'Novice Adventurer';
    }
    if (level <= 10) {
      return 'Apprentice Adventurer';
    }
    if (level <= 20) {
      return 'Hero Adventurer';
    }
    return 'Legend Adventurer';
  }
}
