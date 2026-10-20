import 'package:actiphibian/models/task.dart';
import 'package:actiphibian/services/recurrence.dart';
import 'package:actiphibian/services/task_labels.dart';

/// One chip on the calendar. A recurring task has one entry per repeat, each with its own due time.
class CalendarEntry {
  final Task task;
  final DateTime due;
  const CalendarEntry(this.task, this.due);
}

class CalendarSnippet {
  final String title;
  final String deadlineText;
  final String subtaskText;
  final String difficultyText;

  const CalendarSnippet({
    required this.title,
    required this.deadlineText,
    required this.subtaskText,
    required this.difficultyText,
  });
}

class CalendarLogic {
  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Still not tested but am aiming to ensure a way for the app to not be affected by daylight-saving time shifts.
  /// Will remove if not necessary since I would need to seperate storage of time from its presentation
  static List<DateTime> monthGrid(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final offset = first.weekday - DateTime.monday;
    return List<DateTime>.generate(
      42,
      (i) => DateTime(first.year, first.month, 1 - offset + i),
    );
  }

  /// Finished and cancelled tasks are removed; a missed task stays because it can still be completed.
  static bool isOnCalendar(Task task) =>
      task.status == 'active' || task.status == 'missed';

  static Map<DateTime, List<CalendarEntry>> entriesByDay(
    Iterable<Task> tasks, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required DateTime today,
  }) {
    final start = dayOf(rangeStart);
    final end = dayOf(rangeEnd);
    final todayStart = dayOf(today);
    final map = <DateTime, List<CalendarEntry>>{};

    void add(Task task, DateTime due) {
      map
          .putIfAbsent(dayOf(due), () => <CalendarEntry>[])
          .add(CalendarEntry(task, due));
    }

    for (final task in tasks) {
      final deadline = task.deadline;
      if (deadline == null || !isOnCalendar(task)) continue;

      add(task, deadline);

      final frequency = task.recurrenceFrequency;
      if (task.isRecurring && frequency != null) {
        var n = 1;
        while (true) {
          final due = Recurrence.occurrenceAt(deadline, frequency, n);
          if (dayOf(due).isAfter(end)) break;
          if (!dayOf(due).isBefore(start) && !dayOf(due).isBefore(todayStart)) {
            add(task, due);
          }
          n++;
        }
      }
    }

    for (final list in map.values) {
      list.sort((a, b) {
        final byTime = a.due.compareTo(b.due);
        return byTime != 0
            ? byTime
            : a.task.description.compareTo(b.task.description);
      });
    }
    return map;
  }

  static int habitColorIndex(int? habitId, int paletteSize) {
    if (habitId == null || paletteSize <= 0) return -1;
    return habitId.abs() % paletteSize;
  }

  static String spanLabel(Duration d) {
    final minutes = d.inMinutes.abs();
    if (minutes < 1) return 'less than a minute';
    if (minutes < 60) return '$minutes min';
    if (minutes < 24 * 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '$h h' : '$h h $m min';
    }
    final days = minutes ~/ (24 * 60);
    final h = (minutes % (24 * 60)) ~/ 60;
    final dayText = days == 1 ? '1 day' : '$days days';
    return h == 0 ? dayText : '$dayText $h h';
  }

  static String deadlineText(Task task, DateTime now, {DateTime? due}) {
    if (task.status == 'completed') return 'Completed';
    if (task.status == 'cancelled') return 'Cancelled';
    final deadline = due ?? task.deadline;
    if (deadline == null) return 'No deadline';
    final diff = deadline.difference(now);
    if (diff.isNegative) return 'Overdue by ${spanLabel(diff)}';
    return 'Due in ${spanLabel(diff)}';
  }

  static CalendarSnippet snippet(Task task, DateTime now, {DateTime? due}) =>
      CalendarSnippet(
        title: task.description.isEmpty ? '(untitled task)' : task.description,
        deadlineText: deadlineText(task, now, due: due),
        subtaskText: task.hasSubtasks
            ? TaskLabels.subtaskLabel(task)
            : 'No subtasks',
        difficultyText: TaskLabels.difficultyLabel(task.difficulty),
      );
}
