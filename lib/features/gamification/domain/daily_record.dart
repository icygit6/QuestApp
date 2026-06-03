/// Hive-backed daily completion counter used for streaks and charts.
class DailyRecord {
  const DailyRecord({required this.dateKey, required this.completedCount});

  final String dateKey;
  final int completedCount;

  DailyRecord increment() {
    return DailyRecord(dateKey: dateKey, completedCount: completedCount + 1);
  }
}
