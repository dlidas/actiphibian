/// Please do not touch.
class CurrencyCalculator {
  static const Map<String, int> _baseCurrencyByDifficulty = {
    'easy': 5,
    'medium': 12,
    'hard': 25,
  };
  /// +5%/day completed ahead of the deadline, capped at 30%. 
  static const double maxEarlyBonus = 0.3;
  static const double earlyBonusPerDay = 0.05;

  /// +2% per habit/tag level, capped at 40% (maxes out around level 20).
  static const double maxTagLevelBonus = 0.4;
  static const double tagLevelBonusPerLevel = 0.02;

  /// +3% per day of current streak, capped at 60% (maxes out around a
  /// 20-day streak). It takes 21 day to from a habit niche reference.
  static const double maxStreakBonus = 0.6;
  static const double streakBonusPerDay = 0.03;

  /// Belt-and-suspenders cap on top of the three bonuses combined. Just a safety measure so that the distinct bonuses don't exceed their limited 
  static const double maxTotalBonus = 1.0;

  static int baseCurrency(String difficulty) => _baseCurrencyByDifficulty[difficulty] ?? 5;

  static int currencyForCompletion({
    required String predictedDifficulty,
    String? perceivedDifficulty,
    DateTime? deadline,
    required DateTime completedAt,
    int habitLevel = 0,
    int currentStreak = 0,
  }) {
    final effectiveDifficulty = perceivedDifficulty ?? predictedDifficulty;
    final base = baseCurrency(effectiveDifficulty);

    double earlyBonus = 0;
    if (deadline != null && !completedAt.isAfter(deadline)) {
      final daysEarly = deadline.difference(completedAt).inHours / 24;
      earlyBonus = (daysEarly * earlyBonusPerDay).clamp(0.0, maxEarlyBonus);
    }

    final tagLevelBonus = (habitLevel * tagLevelBonusPerLevel).clamp(0.0, maxTagLevelBonus);
    final streakBonus = (currentStreak * streakBonusPerDay).clamp(0.0, maxStreakBonus);

    final totalBonus = (earlyBonus + tagLevelBonus + streakBonus).clamp(0.0, maxTotalBonus);
    return (base * (1 + totalBonus)).round();
  }
}