import 'package:actiphibian/models/task.dart';

enum TaskStage { done, inProgress, notStarted, missed, cancelled }

class TodaySummary {
  final int done;
  final int total;
  const TodaySummary(this.done, this.total);

  String get label => '$done of $total complete';
}

class TaskLabels {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static TaskStage stageOf(Task task) {
    if (task.status == 'completed') return TaskStage.done;
    if (task.status == 'cancelled') return TaskStage.cancelled;
    if (task.status == 'missed') return TaskStage.missed;
    if (task.hasSubtasks && task.subtasksCompletedCount > 0) {
      return TaskStage.inProgress;
    }
    return TaskStage.notStarted;
  }

  static String deadlineLabel(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]} ${d.year}, $hh:$mm';
  }

  static String difficultyLabel(String stored) {
    switch (stored) {
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return 'Easy';
    }
  }

  static String durationLabel(int? minutes) {
    if (minutes == null || minutes <= 0) return '';
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  static String subtaskLabel(Task task) {
    final noun = task.subtasksTotalCount == 1 ? 'subtask' : 'subtasks';
    return '${task.subtasksCompletedCount} of ${task.subtasksTotalCount} $noun';
  }

  static String completedLabel(Task task, DateTime now) {
    final at = task.completedAt;
    if (at == null) return 'Completed';
    if (_sameDay(at, now)) return 'Completed today';
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (_sameDay(at, yesterday)) return 'Completed yesterday';
    return 'Completed ${_months[at.month - 1]} ${at.day}';
  }

  static String xpChip(Task task) => '+${task.xpAwarded} XP';

  static String subtitle(Task task, DateTime now) {
    final stage = stageOf(task);
    if (stage == TaskStage.done) return completedLabel(task, now);
    if (stage == TaskStage.cancelled) return 'Cancelled';
    if (stage == TaskStage.missed) return 'Missed · no XP lost';
    if (stage == TaskStage.inProgress) return subtaskLabel(task);

    final parts = <String>[];
    final duration = durationLabel(task.durationMinutes);
    if (duration.isNotEmpty) parts.add(duration);
    final overdue = task.deadline != null && task.deadline!.isBefore(now);
    parts.add(overdue ? 'Overdue' : 'Not started');
    return parts.join(' · ');
  }

  static bool isTodaysTask(Task task, DateTime now) {
    if (task.status == 'cancelled') return false;
    final completedToday =
        task.status == 'completed' &&
        task.completedAt != null &&
        _sameDay(task.completedAt!, now);
    final dueToday = task.deadline != null && _sameDay(task.deadline!, now);
    return completedToday || dueToday;
  }

  static TodaySummary todaySummary(Iterable<Task> tasks, DateTime now) {
    var done = 0;
    var total = 0;
    for (final t in tasks) {
      if (!isTodaysTask(t, now)) continue;
      total++;
      if (t.status == 'completed') done++;
    }
    return TodaySummary(done, total);
  }
}
