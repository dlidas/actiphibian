import 'package:actiphibian/models/focus_session.dart';
import 'package:actiphibian/models/task.dart';
import 'package:actiphibian/services/gacha_economy.dart';
import 'package:actiphibian/services/rank_table.dart';
import 'package:actiphibian/services/streak_calculator.dart';
import 'package:actiphibian/utils/number_format.dart';

class UserProgress {
  final int totalXp;
  final Rank rank;
  final Rank? nextRank;
  final int level;
  final int streak;

  final int coinsSpent;

  const UserProgress({
    required this.totalXp,
    required this.rank,
    required this.nextRank,
    required this.level,
    required this.streak,
    this.coinsSpent = 0,
  });

  factory UserProgress.fromTasks(
    List<Task> tasks, {
    required DateTime now,
    int coinsSpent = 0,
    Iterable<FocusSession> focusSessions = const [],
  }) {
    final completed = tasks.where((t) => t.status == 'completed').toList();
    final taskXp = completed.fold<int>(0, (sum, t) => sum + t.xpAwarded);
    final focusXp = focusSessions.fold<int>(0, (sum, f) => sum + f.xpAwarded);
    final totalXp = taskXp + focusXp;
    final completionTimes = completed
        .where((t) => t.completedAt != null)
        .map((t) => t.completedAt!);

    return UserProgress(
      totalXp: totalXp,
      rank: RankTable.rankForXp(totalXp),
      nextRank: RankTable.nextRankForXp(totalXp),
      level: RankTable.levelForXp(totalXp),
      streak: StreakCalculator.currentStreak(completionTimes, now),
      coinsSpent: coinsSpent,
    );
  }

  // Coins

  /// Lifetime coins earned
  int get coinsEarned => GachaEconomy.coinsEarned(totalXp);

  /// Spendable coins
  int get coins =>
      GachaEconomy.balance(totalXp: totalXp, coinsSpent: coinsSpent);

  bool get canAffordSinglePull => GachaEconomy.canAffordSinglePull(coins);
  bool get canAffordTenPlusOne => GachaEconomy.canAffordTenPlusOne(coins);

  // Rank bar

  /// XP still needed for the next rank
  int? get xpToNextRank => nextRank == null ? null : nextRank!.minXp - totalXp;

  double get progressToNextRank {
    final next = nextRank;
    if (next == null || next.minXp == 0) return 1.0;
    return (totalXp / next.minXp).clamp(0.0, 1.0).toDouble();
  }

  String get progressLabel => nextRank == null
      ? 'Max rank'
      : '${formatCount(totalXp)} / ${formatCount(nextRank!.minXp)} XP';

  static Rank? rankReached(UserProgress before, UserProgress after) =>
      after.level > before.level ? after.rank : null;
}
