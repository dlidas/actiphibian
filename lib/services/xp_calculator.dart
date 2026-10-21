import 'dart:math';

class XpCalculator {
  static const Map<String, int> _baseXpByDifficulty = {
    'easy': 10,
    'medium': 25,
    'hard': 50,
  };

  static const double maxEarlyBonus = 0.5;
  static const double earlyBonusPerDay = 0.05;
  static const int fullRateTasksPerDay = 5;
  static const int reducedRateTasksPerDay = 10;
  static const double reducedRateMultiplier = 0.5;
  static const double tailRateMultiplier = 0.25;
  static int baseXp(String difficulty) => _baseXpByDifficulty[difficulty] ?? 10;

  static double dailyMultiplier(int completionsBefore) {
    if (completionsBefore < fullRateTasksPerDay) return 1.0;
    if (completionsBefore < reducedRateTasksPerDay) {
      return reducedRateMultiplier;
    }
    return tailRateMultiplier;
  }

  static int completionsOnDay(
    Iterable<DateTime> completionTimes,
    DateTime day,
  ) {
    return completionTimes
        .where(
          (t) => t.year == day.year && t.month == day.month && t.day == day.day,
        )
        .length;
  }

  static double earlyBonus({
    required DateTime createdAt,
    DateTime? deadline,
    required DateTime completedAt,
  }) {
    if (deadline == null) return 0.0;
    if (completedAt.isAfter(deadline)) return 0.0;

    final daysEarly = deadline.difference(completedAt).inHours / 24;
    final daysSinceCreation = completedAt.difference(createdAt).inHours / 24;
    final effectiveDaysEarly = min(daysEarly, daysSinceCreation);

    return (effectiveDaysEarly * earlyBonusPerDay)
        .clamp(0.0, maxEarlyBonus)
        .toDouble();
  }

  static int xpForCompletion({
    required String difficulty,
    required DateTime createdAt,
    DateTime? deadline,
    required DateTime completedAt,
    int completionsToday = 0,
  }) {
    final base = baseXp(difficulty);
    final bonus = earlyBonus(
      createdAt: createdAt,
      deadline: deadline,
      completedAt: completedAt,
    );
    return (base * (1 + bonus) * dailyMultiplier(completionsToday)).round();
  }
}
