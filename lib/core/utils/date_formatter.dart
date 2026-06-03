import 'package:intl/intl.dart';

/// Date formatting helpers for display and local streak keys.
abstract final class DateFormatter {
  static final DateFormat _readable = DateFormat('MMM d, yyyy');
  static final DateFormat _key = DateFormat('yyyy-MM-dd');

  static String readable(DateTime date) => _readable.format(date);

  static String dayKey(DateTime date) => _key.format(date);

  static bool isYesterday(DateTime previous, DateTime current) {
    final prev = DateTime(previous.year, previous.month, previous.day);
    final now = DateTime(current.year, current.month, current.day);
    return now.difference(prev).inDays == 1;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
