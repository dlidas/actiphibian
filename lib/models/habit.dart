class Habit {
  final int? id;
  final String name;
  final int totalXp;
  final DateTime createdAt;
  final int currentStreak;

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

  double get progressToNextLevel =>
      xpNeededForNextLevel == 0 ? 0 : xpIntoCurrentLevel / xpNeededForNextLevel;
}
