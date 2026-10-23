import 'dart:convert';

/// Check sub-task
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

/// status is 'active' | 'completed' | 'missed' | 'cancelled'
class Task {
  final int? id;
  final String description;
  final List<Subtask> subtasks;
  final int? durationMinutes;
  final DateTime? deadline;
  final bool recurring;
  final String? recurrenceFrequency;
  final String difficulty;
  // Optional rating given after completing; null means the user skipped it.
  final String? perceivedDifficulty;
  final String status;
  final int xpAwarded;
  final DateTime? completedAt;
  final int? habitId;

  /// Stable identifier shared by every occurrence in the same recurring series.
  final String? recurringSeriesId;
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
    this.recurrenceFrequency,
    required this.difficulty,
    this.perceivedDifficulty,
    this.status = 'active',
    this.xpAwarded = 0,
    this.completedAt,
    this.habitId,
    this.recurringSeriesId,
    this.remoteId,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  static const Object _unset = Object();

  Task copyWith({
    int? id,
    String? description,
    List<Subtask>? subtasks,
    Object? durationMinutes = _unset,
    Object? deadline = _unset, 
    bool? recurring,
    Object? recurrenceFrequency = _unset, 
    String? difficulty,
    String? perceivedDifficulty,
    String? status,
    int? xpAwarded,
    DateTime? completedAt,
    Object? habitId = _unset,
    Object? recurringSeriesId = _unset, 
    String? remoteId,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      description: description ?? this.description,
      subtasks: subtasks ?? this.subtasks,
      durationMinutes: identical(durationMinutes, _unset)
          ? this.durationMinutes
          : durationMinutes as int?,
      deadline: identical(deadline, _unset)
          ? this.deadline
          : deadline as DateTime?,
      recurring: recurring ?? this.recurring,
      recurrenceFrequency: identical(recurrenceFrequency, _unset)
          ? this.recurrenceFrequency
          : recurrenceFrequency as String?,
      difficulty: difficulty ?? this.difficulty,
      perceivedDifficulty: perceivedDifficulty ?? this.perceivedDifficulty,
      status: status ?? this.status,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      completedAt: completedAt ?? this.completedAt,
      habitId: identical(habitId, _unset) ? this.habitId : habitId as int?,
      recurringSeriesId: identical(recurringSeriesId, _unset)
          ? this.recurringSeriesId
          : recurringSeriesId as String?,
      remoteId: remoteId ?? this.remoteId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'subtasks': jsonEncode(subtasks.map((s) => s.toMap()).toList()),
      'durationMinutes': durationMinutes,
      'deadline': deadline?.toIso8601String(),
      'recurring': recurring ? 1 : 0,
      'recurrenceFrequency': recurrenceFrequency,
      'difficulty': difficulty,
      'perceivedDifficulty': perceivedDifficulty,
      'status': status,
      'xpAwarded': xpAwarded,
      'completedAt': completedAt?.toIso8601String(),
      'habitId': habitId,
      'recurringSeriesId': recurringSeriesId,
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
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      recurring: (map['recurring'] as int) == 1,
      recurrenceFrequency: map['recurrenceFrequency'] as String?,
      difficulty: map['difficulty'] as String,
      perceivedDifficulty: map['perceivedDifficulty'] as String?,
      status: map['status'] as String? ?? 'active',
      xpAwarded: map['xpAwarded'] as int? ?? 0,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      habitId: map['habitId'] as int?,
      recurringSeriesId: map['recurringSeriesId'] as String?,
      remoteId: map['remoteId']?.toString(),
      isSynced: (map['isSynced'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  bool get isRecurring => recurring && recurrenceFrequency != null;

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

  bool get hasSubtasks => subtasks.isNotEmpty;
  int get subtasksTotalCount => subtasks.length;
  int get subtasksCompletedCount => subtasks.where((s) => s.isDone).length;

  double get subtaskProgress => subtasksTotalCount == 0
      ? 1.0
      : subtasksCompletedCount / subtasksTotalCount;
}
