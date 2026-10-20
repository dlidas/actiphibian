class TaskFormErrors {
  final String? description;
  final String? deadline;
  final String? frequency;

  const TaskFormErrors({this.description, this.deadline, this.frequency});

  bool get hasErrors =>
      description != null || deadline != null || frequency != null;
}

class TaskFormValidator {
  static TaskFormErrors validate({
    required String description,
    required DateTime? deadline,
    required bool recurring,
    required String? frequency,
    required DateTime now,
    bool checkPast = true,
  }) {
    String? descriptionError;
    String? deadlineError;
    String? frequencyError;

    if (description.trim().isEmpty) {
      descriptionError = 'Give the task a description';
    }

    if (recurring && frequency == null) {
      frequencyError = 'Choose how often it repeats';
    }

    if (deadline == null) {
      if (!recurring) deadlineError = 'Pick a deadline';
    } else if (checkPast && deadline.isBefore(now)) {
      deadlineError = recurring
          ? 'That first-due time has already passed'
          : 'That deadline has already passed';
    }

    return TaskFormErrors(
      description: descriptionError,
      deadline: deadlineError,
      frequency: frequencyError,
    );
  }
}
