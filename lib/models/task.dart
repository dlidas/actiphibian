import 'dart:convert';

// Please do not touch. Just please. I will be very sad if you do. I will cry. I will cry a lot. 
//I will cry a lot and then I will be sad for a long time. Please don't touch this file. 
//It is very important to me. It is my baby. 
//It is my precious child. 
//It is my baby and my precious child and it is very important to me and I love it very much and I will be very sad if you touch it. 
//Please don't touch it. Please don't touch it. Please don't touch it.
class Subtask {
  final String text;
  final bool isDone;

  const Subtask({required this.text, this.isDone = false});

  Subtask copyWith({String? text, bool? isDone}) {
    return Subtask(text: text ?? this.text, isDone: isDone ?? this.isDone);
  }

  Map<String, dynamic> toMap() => {'text': text, 'isDone': isDone};

  factory Subtask.fromMap(Map<String, dynamic> map) => Subtask(
        text: map['text'] as String,
        isDone: map['isDone'] as bool? ?? false,
      );
}

class Task {
  final int? id;
  final String description;
  final List<Subtask> subtasks;
  final int? durationMinutes;
  final DateTime? deadline;
  final bool recurring;
  final String difficulty; 
  final String? perceivedDifficulty;
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
    this.perceivedDifficulty,
    this.status = 'active',
    this.xpAwarded = 0,
    this.completedAt,
    this.habitId,
    this.remoteId,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Task copyWith({
    int? id,
    String? description,
    List<Subtask>? subtasks,
    int? durationMinutes,
    DateTime? deadline,
    bool? recurring,
    String? difficulty,
    String? perceivedDifficulty,
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
      perceivedDifficulty: perceivedDifficulty ?? this.perceivedDifficulty,
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

  // Serializing for database storage (this is just the prep) btw who is JSON and why is he everywhere?
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'subtasks': jsonEncode(subtasks.map((s) => s.toMap()).toList()),
      'durationMinutes': durationMinutes,
      'deadline': deadline?.toIso8601String(),
      'recurring': recurring ? 1 : 0,
      'difficulty': difficulty,
      'perceivedDifficulty': perceivedDifficulty,
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
          ? (jsonDecode(map['subtasks'] as String) as List)
              .map((m) => Subtask.fromMap(m as Map<String, dynamic>))
              .toList()
          : const [],
      durationMinutes: map['durationMinutes'] as int?,
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
      recurring: (map['recurring'] as int) == 1,
      difficulty: map['difficulty'] as String,
      perceivedDifficulty: map['perceivedDifficulty'] as String?,
      status: map['status'] as String? ?? 'active',
      xpAwarded: map['xpAwarded'] as int? ?? 0,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
      habitId: map['habitId'] as int?,
      remoteId: map['remoteId'] as String?,
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

 // Check if the task is due today
  bool get isDueToday {
    if (deadline == null) return false;
    final now = DateTime.now();
    return deadline!.year == now.year && deadline!.month == now.month && deadline!.day == now.day;
  }
 // Check if the task is overdue
  bool get isOverdue {
    if (deadline == null || status != 'active') return false;
    return deadline!.isBefore(DateTime.now());
  }

  // Subtask completed counter
  bool get hasSubtasks => subtasks.isNotEmpty;
  int get subtasksTotalCount => subtasks.length;
  int get subtasksCompletedCount => subtasks.where((s) => s.isDone).length;

// Progress calculation for the progress widget, returns a value between 0.0 and 1.0
  double get subtaskProgress =>
      subtasksTotalCount == 0 ? 1.0 : subtasksCompletedCount / subtasksTotalCount;

}