/// Are you a habit because your a tag? Or are you tag because your a habit?
/// This is the model for a habit, which is a tag that can be tracked and leveled up. It has a name, total XP, current streak, and created at date. 
/// It also has methods for converting to and from a map, copying with new values, and calculating level and progress to next level.
/// That last part is work in progress that I expect I will be clowned on for making it so inefficient.
class Habit {
  final int? id;
  final String name;
  final int totalXp;
  final int currentStreak;
  final DateTime createdAt;

  Habit({
    this.id,
    required this.name,
    this.totalXp = 0,
    this.currentStreak = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalXp': totalXp,
      'currentStreak': currentStreak,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      name: map['name'] as String,
      totalXp: map['totalXp'] as int,
      currentStreak: map['currentStreak'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Habit copyWith({
    int? id,
    String? name,
    int? totalXp,
    int? currentStreak,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Linear leveling curve: I'll still keep like this for now. I'll make it exponential this week when I can reliably test out xp gain.
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

