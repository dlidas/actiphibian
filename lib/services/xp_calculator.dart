/// This is where the xp calculations live.
/// It will make it easier for me to change to the exponoential leveling curve later, and it will also make it easier to test the xp calculations in isolation.
/// I just have basic constant shape right now but the nitty gritty can be fine-tuned.
class XpCalculator {
  static const Map<String, int> _baseXpByDifficulty = {
    'easy': 10,
    'medium': 25,
    'hard': 50,
  };

  /// Missing a task costs half of what completing it would have earned.
  static const double missedPenaltyFactor = 0.5;

  /// Completing early can boost the reward by up to +50%.
  static const double maxEarlyBonus = 0.5;

  /// +5% bonus per full day completed ahead of the deadline, capped at
  /// maxEarlyBonus above.
  static const double earlyBonusPerDay = 0.05;

  static int baseXp(String difficulty) => _baseXpByDifficulty[difficulty] ?? 10;

  /// XP awarded for completing a task. If there's no deadline, timing
  /// can't be evaluated, so it just earns its base amount. Completing
  /// after the deadline  also just earns base, no bonus and no penalty:
  /// the penalty for being late is handled separately, by the
  /// missed-task check, not by this function.
  static int xpForCompletion({
    required String difficulty,
    DateTime? deadline,
    required DateTime completedAt,
  }) {
    final base = baseXp(difficulty);
    if (deadline == null) return base;
    if (completedAt.isAfter(deadline)) return base;

    final daysEarly = deadline.difference(completedAt).inHours / 24;
    final bonus = (daysEarly * earlyBonusPerDay).clamp(0.0, maxEarlyBonus);
    return (base * (1 + bonus)).round();
  }

  /// XP deducted from the habit when a task's deadline passes with the
  /// task still pending (never completed, never cancelled).
  static int xpPenaltyForMissed(String difficulty) {
    return (baseXp(difficulty) * missedPenaltyFactor).round();
  }
}