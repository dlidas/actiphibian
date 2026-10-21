import 'package:actiphibian/models/focus_session.dart';

/// To stop user from spamming focus to just earn xp for coins, focus session have cap limit on how much xp they can earn.
/// There's a minimum focus time they must have for them to even earn xp.
/// Only credit the first 2hrs of the focus session.
/// Thats roughly a one hard task and medium task base xp {without any special modifier like streaks}

class FocusXp {
  static const int minutesPerXp = 3;
  static const int minSessionMinutes = 5;
  static const int dailyCapMinutes = 120;

  static int focusMinutesOnDay(Iterable<FocusSession> sessions, DateTime day) {
    var total = 0;
    for (final s in sessions) {
      final t = s.startedAt;
      if (t.year == day.year && t.month == day.month && t.day == day.day) {
        total += s.focusedMinutes;
      }
    }
    return total;
  }

  static int xpForSession({
    required int focusedMinutes,
    int focusMinutesToday = 0,
  }) {
    if (focusedMinutes < minSessionMinutes) return 0;
    final remaining = dailyCapMinutes - focusMinutesToday;
    if (remaining <= 0) return 0;
    final credited = focusedMinutes < remaining ? focusedMinutes : remaining;
    return credited ~/ minutesPerXp;
  }
}
