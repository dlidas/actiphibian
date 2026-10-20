class GachaEconomy {
  static const int xpPerCoin = 4;

  static const int singlePullCost = 50;
  static const int tenPlusOneCost = 500;

  static const int singlePullCount = 1;

  static const int tenPlusOnePullCount = 11;

  /// Lifetime coins
  static int coinsEarned(int totalXp) =>
      totalXp <= 0 ? 0 : totalXp ~/ xpPerCoin;

  /// Spendable coins
  static int balance({required int totalXp, int coinsSpent = 0}) {
    final b = coinsEarned(totalXp) - coinsSpent;
    return b < 0 ? 0 : b;
  }

  static bool canAffordSinglePull(int balance) => balance >= singlePullCost;

  static bool canAffordTenPlusOne(int balance) => balance >= tenPlusOneCost;

  static int singlePullsAffordable(int balance) =>
      balance <= 0 ? 0 : balance ~/ singlePullCost;

  static int? coinsSpentAfter({
    required int totalXp,
    required int coinsSpent,
    required int cost,
  }) {
    if (balance(totalXp: totalXp, coinsSpent: coinsSpent) < cost) return null;
    return coinsSpent + cost;
  }
}
