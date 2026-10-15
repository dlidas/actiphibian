import 'dart:convert';

class Task {
  final int? id;
  final String description;
  final List<String> subtasks;
  final int? durationMinutes;
  final DateTime? deadline;
  final bool recurring;
  final String difficulty;
  final String status; // "active" | "completed" | "missed" | "cancelled"
  final int xpAwarded;
  final DateTime? completedAt;
  final int? habitId;
  final String? remoteId;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    this.id,
    required this.description,
    this.subtasks = const [],
    this.durationMinutes,
    this.deadline,
    required this.recurring,
    required this.difficulty,
    this.status = 'active',
    this.xpAwarded = 0,
    this.completedAt,
    this.habitId,
    this.remoteId,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Task copyWith({
    int? id,
    String? description,
    List<String>? subtasks,
    int? durationMinutes,
    DateTime? deadline,
    bool? recurring,
    String? difficulty,
    String? status,
    int? xpAwarded,
    DateTime? completedAt,
    int? habitId,
    String? remoteId,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      description: description ?? this.description,
      subtasks: subtasks ?? this.subtasks,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      deadline: deadline ?? this.deadline,
      recurring: recurring ?? this.recurring,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      completedAt: completedAt ?? this.completedAt,
      habitId: habitId ?? this.habitId,
      remoteId: remoteId ?? this.remoteId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Mapping to the SQlite [not wired it]
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'subtasks': jsonEncode(subtasks),
      'durationMinutes': durationMinutes,
      'deadline': deadline?.toIso8601String(),
      'recurring': recurring ? 1 : 0,
      'difficulty': difficulty,
      'status': status,
      'xpAwarded': xpAwarded,
      'completedAt': completedAt?.toIso8601String(),
      'habitId': habitId,
      'remoteId': remoteId,
      'isSynced': isSynced ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      description: map['description'] as String,
      subtasks: map['subtasks'] != null
          ? List<String>.from(jsonDecode(map['subtasks'] as String) as List)
          : const [],
      durationMinutes: map['durationMinutes'] as int?,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      recurring: (map['recurring'] as int) == 1,
      difficulty: map['difficulty'] as String,
      status: map['status'] as String? ?? 'active',
      xpAwarded: map['xpAwarded'] as int? ?? 0,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      habitId: map['habitId'] as int?,
      remoteId: map['remoteId'] as String?,
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  bool get isDueToday {
    if (deadline == null) return false;
    final now = DateTime.now();
    return deadline!.year == now.year &&
        deadline!.month == now.month &&
        deadline!.day == now.day;
  }

  bool get isOverdue {
    if (deadline == null || status != 'active') return false;
    return deadline!.isBefore(DateTime.now());
  }
}
