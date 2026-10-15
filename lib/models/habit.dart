/// A general skill the user wants to level up by completing tasks under it
/// Example: Hygiene, Academic, Music, Health. Tasks reference a habit
/// by id; completing/missing a task moves that habit's XP up or down.
class Habit {
  final int? id;
  final String name;
  final int totalXp;
  final DateTime createdAt;

  Habit({this.id, required this.name, this.totalXp = 0, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalXp': totalXp,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      name: map['name'] as String,
      totalXp: map['totalXp'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Habit copyWith({int? id, String? name, int? totalXp, DateTime? createdAt}) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      totalXp: totalXp ?? this.totalXp,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// For the time being, levelling has a linear curve.
  /// Level N needs N*100 cumulative XP. But you can quickly see the issue for this.
  /// When a habit reaches level 6, it will need 700 XP to reach level 8. Am going to either A)implement a logarithmic curve or B) make the level XP requirement a constant value. For now, I will go with option B.
  /// The logarithmic curve is more realistic (easier to improve on something early but harder to improve on something later), but it will be a pain to implement. I will go with option B for now.
  /// There's also the fact that XP earned from task completion is not linear.
  static int _xpForLevel(int level) => level * 100;

  (int level, int xpIntoLevel) _levelInfo() {
    int lvl = 1;
    int remaining = totalXp < 0 ? 0 : totalXp;
    while (remaining >= _xpForLevel(lvl)) {
      remaining -= _xpForLevel(lvl);
      lvl++;
    }
    return (lvl, remaining);
  }

  int get level => _levelInfo().$1;
  int get xpIntoCurrentLevel => _levelInfo().$2;
  int get xpNeededForNextLevel => _xpForLevel(level);

  /// 0.0–1.0, for a progress bar widget.
  double get progressToNextLevel =>
      xpNeededForNextLevel == 0 ? 0 : xpIntoCurrentLevel / xpNeededForNextLevel;
}
