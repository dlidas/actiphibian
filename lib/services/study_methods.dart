class StudyMethod {
  final String id;
  final String name;
  final String summary;
  final int focusMinutes;
  final int breakMinutes;
  final double xpMultiplier;

  const StudyMethod({
    required this.id,
    required this.name,
    required this.summary,
    required this.focusMinutes,
    required this.breakMinutes,
    this.xpMultiplier = 1.0,
  });
}

class StudyMethods {
  static const StudyMethod pomodoro = StudyMethod(
    id: 'pomodoro',
    name: 'Pomodoro',
    summary: 'Short focused sprints with a break after each.',
    focusMinutes: 25,
    breakMinutes: 5,
  );

  static const StudyMethod timeBlocking = StudyMethod(
    id: 'time_blocking',
    name: 'Time blocking',
    summary: 'Give each task its own block of time in your day.',
    focusMinutes: 60,
    breakMinutes: 10,
  );

  static const StudyMethod eatThatFrog = StudyMethod(
    id: 'eat_that_frog',
    name: 'Eat that frog',
    summary: 'Do your hardest task first, before anything else.',
    focusMinutes: 50,
    breakMinutes: 10,
  );

  static const StudyMethod parkinsonsLaw = StudyMethod(
    id: 'parkinsons_law',
    name: "Parkinson's law",
    summary: 'Set a deliberately tight time limit and beat it.',
    focusMinutes: 30,
    breakMinutes: 5,
  );

  static const StudyMethod taskBatching = StudyMethod(
    id: 'task_batching',
    name: 'Task batching',
    summary: 'Group similar tasks and do them in one sitting.',
    focusMinutes: 45,
    breakMinutes: 10,
  );

  static const List<StudyMethod> all = [
    pomodoro,
    timeBlocking,
    eatThatFrog,
    parkinsonsLaw,
    taskBatching,
  ];

  /// Used when the user skipped the questionnaire and hasn't chosen.
  static const StudyMethod defaultMethod = pomodoro;

  static StudyMethod? byId(String? id) {
    if (id == null) return null;
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }

  static StudyMethod methodForTimer({
    String? selectedId,
    String? recommendedId,
  }) {
    return byId(selectedId) ?? byId(recommendedId) ?? defaultMethod;
  }
}
