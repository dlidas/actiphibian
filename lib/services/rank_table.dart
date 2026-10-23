class Rank {
  final String name;

  /// Total XP a user needs to hold this rank.
  final int minXp;

  const Rank(this.name, this.minXp);
}

class RankTable {
  static const List<Rank> ranks = [
    Rank('Egg', 0),
    Rank('Polliwog ', 200),
    Rank('Tadpole ', 800),
    Rank('Froglet ', 1500),
    Rank('Pond Frog', 3500),
    Rank('Bullfrog', 7000),
    Rank('Axolotl', 12000),
  ];

  static int indexForXp(int totalXp) {
    final xp = totalXp < 0 ? 0 : totalXp;
    var index = 0;
    for (var i = 0; i < ranks.length; i++) {
      if (xp >= ranks[i].minXp) index = i;
    }
    return index;
  }

  static Rank rankForXp(int totalXp) => ranks[indexForXp(totalXp)];

  static int levelForXp(int totalXp) => indexForXp(totalXp) + 1;

  static Rank? nextRankForXp(int totalXp) {
    final next = indexForXp(totalXp) + 1;
    return next < ranks.length ? ranks[next] : null;
  }
}
