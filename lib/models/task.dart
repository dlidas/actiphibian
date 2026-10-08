class Task {
  final String description;
  final String subtasks;
  final String duration;
  final String deadline;
  final bool recurring;
  final String difficulty;

  Task({
    required this.description,
    required this.subtasks,
    required this.duration,
    required this.deadline,
    required this.recurring,
    required this.difficulty,
  });

  Map<String, dynamic> toMap() {
    return {
      "description": description,
      "subtasks": subtasks,
      "duration": duration,
      "deadline": deadline,
      "recurring": recurring,
      "difficulty": difficulty,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      description: map["description"],
      subtasks: map["subtasks"],
      duration: map["duration"],
      deadline: map["deadline"],
      recurring: map["recurring"],
      difficulty: map["difficulty"],
    );
  }
}
