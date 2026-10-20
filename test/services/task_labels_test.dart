import 'package:flutter_test/flutter_test.dart';
import 'package:actiphibian/models/task.dart';
import 'package:actiphibian/services/task_labels.dart';

Task _task({
  String status = 'active',
  List<Subtask> subtasks = const [],
  int? minutes,
  DateTime? deadline,
  DateTime? completedAt,
  int xp = 0,
}) {
  return Task(
    description: 'task',
    recurring: false,
    difficulty: 'easy',
    status: status,
    subtasks: subtasks,
    durationMinutes: minutes,
    deadline: deadline,
    completedAt: completedAt,
    xpAwarded: xp,
  );
}

List<Subtask> _subs(int done, int total) => List.generate(
      total,
      (i) => Subtask(text: 's$i', isDone: i < done),
    );

void main() {
  final now = DateTime(2026, 10, 15, 14);

  group('stageOf', () {
    test('maps status to the card stage', () {
      expect(TaskLabels.stageOf(_task(status: 'completed')), TaskStage.done);
      expect(TaskLabels.stageOf(_task(status: 'cancelled')), TaskStage.cancelled);
      expect(TaskLabels.stageOf(_task(status: 'missed')), TaskStage.missed);
    });

    test('an active task is "not started" until a subtask is ticked', () {
      expect(TaskLabels.stageOf(_task()), TaskStage.notStarted);
      expect(TaskLabels.stageOf(_task(subtasks: _subs(0, 5))), TaskStage.notStarted);
      expect(TaskLabels.stageOf(_task(subtasks: _subs(1, 5))), TaskStage.inProgress);
    });
  });

  test('deadlineLabel shows date and 24-hour time', () {
    expect(TaskLabels.deadlineLabel(DateTime(2026, 10, 20, 23, 59)), '20 Oct 2026, 23:59');
    expect(TaskLabels.deadlineLabel(DateTime(2026, 1, 5, 8, 5)), '5 Jan 2026, 08:05');
  });

  test('difficultyLabel capitalises the stored value', () {
    expect(TaskLabels.difficultyLabel('easy'), 'Easy');
    expect(TaskLabels.difficultyLabel('medium'), 'Medium');
    expect(TaskLabels.difficultyLabel('hard'), 'Hard');
    expect(TaskLabels.difficultyLabel('???'), 'Easy');
  });

  group('durationLabel', () {
    test('formats minutes and hours', () {
      expect(TaskLabels.durationLabel(null), '');
      expect(TaskLabels.durationLabel(0), '');
      expect(TaskLabels.durationLabel(45), '45 min');
      expect(TaskLabels.durationLabel(60), '1 h');
      expect(TaskLabels.durationLabel(90), '1 h 30 min');
      expect(TaskLabels.durationLabel(120), '2 h');
    });
  });

  group('subtaskLabel', () {
    test('the wireframe example: 12 of 20', () {
      expect(TaskLabels.subtaskLabel(_task(subtasks: _subs(12, 20))), '12 of 20 subtasks');
    });

    test('singular for a single subtask', () {
      expect(TaskLabels.subtaskLabel(_task(subtasks: _subs(0, 1))), '0 of 1 subtask');
    });
  });

  group('completedLabel', () {
    test('today, yesterday, and an older date', () {
      Task doneAt(DateTime at) => _task(status: 'completed', completedAt: at);
      expect(TaskLabels.completedLabel(doneAt(DateTime(2026, 10, 15, 8)), now), 'Completed today');
      expect(TaskLabels.completedLabel(doneAt(DateTime(2026, 10, 14, 23)), now),
          'Completed yesterday');
      expect(TaskLabels.completedLabel(doneAt(DateTime(2026, 10, 3, 9)), now), 'Completed Oct 3');
    });

    test('yesterday works across a month boundary', () {
      final firstOfMonth = DateTime(2026, 11, 1, 10);
      final t = _task(status: 'completed', completedAt: DateTime(2026, 10, 31, 20));
      expect(TaskLabels.completedLabel(t, firstOfMonth), 'Completed yesterday');
    });

    test('no completion time just says Completed', () {
      expect(TaskLabels.completedLabel(_task(status: 'completed'), now), 'Completed');
    });
  });

  test('xpChip shows the awarded XP', () {
    expect(TaskLabels.xpChip(_task(status: 'completed', xp: 60)), '+60 XP');
  });

  group('subtitle (the second line of each wireframe card)', () {
    test('completed card: "Completed today"', () {
      final t = _task(status: 'completed', completedAt: DateTime(2026, 10, 15, 9), xp: 60);
      expect(TaskLabels.subtitle(t, now), 'Completed today');
    });

    test('in-progress card: "12 of 20 subtasks"', () {
      expect(TaskLabels.subtitle(_task(subtasks: _subs(12, 20)), now), '12 of 20 subtasks');
    });

    test('not-started card: "45 min · Not started"', () {
      expect(TaskLabels.subtitle(_task(minutes: 45), now), '45 min · Not started');
    });

    test('not-started card without a duration: just "Not started"', () {
      expect(TaskLabels.subtitle(_task(), now), 'Not started');
    });

    test('an active task past its deadline reads Overdue', () {
      final t = _task(minutes: 30, deadline: DateTime(2026, 10, 14));
      expect(TaskLabels.subtitle(t, now), '30 min · Overdue');
    });

    test('missed says no XP was lost', () {
      expect(TaskLabels.subtitle(_task(status: 'missed'), now), 'Missed · no XP lost');
    });

    test('cancelled', () {
      expect(TaskLabels.subtitle(_task(status: 'cancelled'), now), 'Cancelled');
    });
  });

  group('isTodaysTask (which cards sit under the "Today\'s Tasks" heading)', () {
    test('due today counts, whether open, missed or already done', () {
      final due = DateTime(2026, 10, 15, 18);
      expect(TaskLabels.isTodaysTask(_task(deadline: due), now), isTrue);
      expect(TaskLabels.isTodaysTask(_task(status: 'missed', deadline: due), now), isTrue);
      expect(
        TaskLabels.isTodaysTask(
            _task(status: 'completed', deadline: due, completedAt: DateTime(2026, 10, 15, 9)), now),
        isTrue,
      );
    });

    test('completed today counts even when the deadline is later', () {
      final t = _task(
        status: 'completed',
        deadline: DateTime(2026, 10, 20),
        completedAt: DateTime(2026, 10, 15, 9),
      );
      expect(TaskLabels.isTodaysTask(t, now), isTrue);
    });

    test('no deadline, a later deadline, or an older completion does not count', () {
      expect(TaskLabels.isTodaysTask(_task(), now), isFalse);
      expect(TaskLabels.isTodaysTask(_task(deadline: DateTime(2026, 10, 25)), now), isFalse);
      expect(
        TaskLabels.isTodaysTask(
            _task(status: 'completed', completedAt: DateTime(2026, 10, 10, 9)), now),
        isFalse,
      );
    });

    test('cancelled never counts, even when due today', () {
      expect(
        TaskLabels.isTodaysTask(
            _task(status: 'cancelled', deadline: DateTime(2026, 10, 15, 18)), now),
        isFalse,
      );
    });

    test('the heading count and the list split always agree', () {
      final tasks = [
        _task(status: 'completed', completedAt: DateTime(2026, 10, 15, 9)),
        _task(deadline: DateTime(2026, 10, 15, 18)),
        _task(deadline: DateTime(2026, 10, 25)),
        _task(),
        _task(status: 'cancelled'),
      ];
      final listed = tasks.where((t) => TaskLabels.isTodaysTask(t, now)).length;
      expect(TaskLabels.todaySummary(tasks, now).total, listed);
    });
  });

  group('todaySummary ("2 of 4 complete")', () {
    test('counts tasks due today and tasks completed today', () {
      final tasks = [
        _task(status: 'completed', completedAt: DateTime(2026, 10, 15, 9)), // done today
        _task(status: 'completed', completedAt: DateTime(2026, 10, 15, 11), // done today, due later
            deadline: DateTime(2026, 10, 20)),
        _task(deadline: DateTime(2026, 10, 15, 18)), // due today, open
        _task(status: 'missed', deadline: DateTime(2026, 10, 15, 8)), // due today, missed
        _task(deadline: DateTime(2026, 10, 25)), // due later: not today's
        _task(), // no deadline, open: not today's
      ];
      final s = TaskLabels.todaySummary(tasks, now);
      expect(s.done, 2);
      expect(s.total, 4);
      expect(s.label, '2 of 4 complete');
    });

    test('cancelled tasks never count', () {
      final tasks = [
        _task(status: 'cancelled', deadline: DateTime(2026, 10, 15, 18)),
      ];
      final s = TaskLabels.todaySummary(tasks, now);
      expect(s.total, 0);
      expect(s.label, '0 of 0 complete');
    });

    test('a task completed on an earlier day does not count toward today', () {
      final tasks = [
        _task(status: 'completed', completedAt: DateTime(2026, 10, 10, 9)),
      ];
      expect(TaskLabels.todaySummary(tasks, now).total, 0);
    });
  });
}
