class StreakCalculator {
  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  static int currentStreak(Iterable<DateTime> completionTimes, DateTime now) {
    final days = completionTimes.map(_dayOf).toSet();
    final today = _dayOf(now);

    var cursor = today;
    if (!days.contains(cursor)) {
      cursor = DateTime(today.year, today.month, today.day - 1);
      if (!days.contains(cursor)) return 0;
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }
}
