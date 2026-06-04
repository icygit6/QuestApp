import 'package:flutter_test/flutter_test.dart';
import 'package:questboard/core/utils/xp_calculator.dart';

void main() {
  group('XpCalculator.xpForNextLevel', () {
    test('uses a 100 * level^1.5 curve', () {
      expect(XpCalculator.xpForNextLevel(1), 100);
      expect(XpCalculator.xpForNextLevel(4), 800); // 100 * 8
      expect(XpCalculator.xpForNextLevel(9), 2700); // 100 * 27
    });

    test('is strictly increasing per level', () {
      var previous = 0;
      for (var level = 1; level <= 30; level++) {
        final current = XpCalculator.xpForNextLevel(level);
        expect(current, greaterThan(previous));
        previous = current;
      }
    });
  });

  group('XpCalculator.xpWithStreakBonus', () {
    test('adds 10% per streak day', () {
      expect(XpCalculator.xpWithStreakBonus(100, 0), 100);
      expect(XpCalculator.xpWithStreakBonus(100, 3), 130);
      expect(XpCalculator.xpWithStreakBonus(100, 5), 150);
    });

    test('caps the bonus at 5 days (50%)', () {
      expect(XpCalculator.xpWithStreakBonus(100, 10), 150);
      expect(XpCalculator.xpWithStreakBonus(100, 100), 150);
    });
  });

  group('XpCalculator.titleForLevel', () {
    test('maps level ranges to adventurer titles', () {
      expect(XpCalculator.titleForLevel(1), 'Novice Adventurer');
      expect(XpCalculator.titleForLevel(5), 'Novice Adventurer');
      expect(XpCalculator.titleForLevel(6), 'Apprentice Adventurer');
      expect(XpCalculator.titleForLevel(10), 'Apprentice Adventurer');
      expect(XpCalculator.titleForLevel(11), 'Hero Adventurer');
      expect(XpCalculator.titleForLevel(20), 'Hero Adventurer');
      expect(XpCalculator.titleForLevel(21), 'Legend Adventurer');
    });
  });
}
