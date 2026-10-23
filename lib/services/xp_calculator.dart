class XpCalculator {
  static const Map<String, int> _baseXpByDifficulty = {
    'easy': 25,
    'medium': 50,
    'hard': 100,
  };

  static const double maxEarlyBonus = 0.5;
  static const double earlyBonusPerDay = 0.05;
  static const int fullRateTasksPerDay = 5;
  static const int reducedRateTasksPerDay = 10;
  static const double reducedRateMultiplier = 0.5;
  static const double tailRateMultiplier = 0.25;

  static const Map<int, int> _recurringMilestoneBonusMultipliers = {
    7: 2,
    21: 5,
    66: 10,
    105: 20,
    200: 50,
  };

  static int baseXp(String difficulty) => _baseXpByDifficulty[difficulty] ?? 10;

  static int recurringMilestoneBonus({
    required String difficulty,
    required int completionCount,
  }) {
    final multiplier =
        _recurringMilestoneBonusMultipliers[completionCount] ?? 0;
    return baseXp(difficulty) * multiplier;
  }

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

  static DateTime _calendarDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static double earlyBonus({
    required DateTime createdAt,
    DateTime? deadline,
    required DateTime completedAt,
    bool isRecurring = false,
  }) {
    // Recurring occurrences are not eligible for early-completion bonuses.
    if (isRecurring || deadline == null) return 0.0;
    if (completedAt.isBefore(createdAt)) return 0.0;

    // Deadlines are date-based. Treat a deadline stored at midnight as the
    // whole calendar day, not as a moment that passes at 00:00.
    final deadlineDay = _calendarDate(deadline);
    final completedDay = _calendarDate(completedAt);
    if (completedDay.isAfter(deadlineDay)) return 0.0;

    final daysEarly = deadlineDay.difference(completedDay).inDays;
    if (daysEarly <= 0) return 0.0;

    // Award the early bonus based on how many calendar days ahead of the
    // deadline the task is completed, capped at the existing 50% maximum.
    return (daysEarly * earlyBonusPerDay).clamp(0.0, maxEarlyBonus).toDouble();
  }

  static int xpForCompletion({
    required String difficulty,
    required DateTime createdAt,
    DateTime? deadline,
    required DateTime completedAt,
    int completionsToday = 0,
    bool isRecurring = false,
    int recurringCompletionCount = 0,
  }) {
    final base = baseXp(difficulty);

    // Recurring tasks receive their normal base XP plus an explicit milestone
    // bonus. They are exempt from early-completion and daily-rate multipliers.
    if (isRecurring) {
      return base +
          recurringMilestoneBonus(
            difficulty: difficulty,
            completionCount: recurringCompletionCount,
          );
    }

    final bonus = earlyBonus(
      createdAt: createdAt,
      deadline: deadline,
      completedAt: completedAt,
      isRecurring: false,
    );
    return (base * (1 + bonus) * dailyMultiplier(completionsToday)).round();
  }
}
