import 'package:flutter_test/flutter_test.dart';
import 'package:actiphibian/models/task.dart';
import 'package:actiphibian/services/calendar_logic.dart';

Task _task({
  String description = 'task',
  DateTime? deadline,
  String status = 'active',
  List<Subtask> subtasks = const [],
  String difficulty = 'easy',
  bool recurring = false,
  String? frequency,
}) {
  return Task(
    description: description,
    recurring: recurring,
    recurrenceFrequency: frequency,
    difficulty: difficulty,
    status: status,
    subtasks: subtasks,
    deadline: deadline,
  );
}

// The October 2026 month view runs from Mon 28 Sep to Sun 8 Nov.
Map<DateTime, List<CalendarEntry>> _entries(
  List<Task> tasks, {
  DateTime? rangeStart,
  DateTime? rangeEnd,
  DateTime? today,
}) {
  return CalendarLogic.entriesByDay(
    tasks,
    rangeStart: rangeStart ?? DateTime(2026, 9, 28),
    rangeEnd: rangeEnd ?? DateTime(2026, 11, 8),
    today: today ?? DateTime(2026, 10, 15),
  );
}

void main() {
  final now = DateTime(2026, 10, 15, 14);

  group('monthGrid', () {
    test('is always 42 days: six Monday-first weeks of consecutive calendar days', () {
      for (var m = 1; m <= 12; m++) {
        final grid = CalendarLogic.monthGrid(DateTime(2026, m));
        expect(grid.length, 42, reason: 'month $m');
        expect(grid.first.weekday, DateTime.monday, reason: 'month $m');
        for (var i = 1; i < grid.length; i++) {
          expect(grid[i], DateTime(grid[i - 1].year, grid[i - 1].month, grid[i - 1].day + 1),
              reason: 'month $m day $i');
        }
        expect(grid.take(7).contains(DateTime(2026, m, 1)), isTrue, reason: 'month $m');
      }
    });

    test('October 2026 starts on Monday 28 September (the 1st is a Thursday)', () {
      final grid = CalendarLogic.monthGrid(DateTime(2026, 10));
      expect(grid.first, DateTime(2026, 9, 28));
      expect(grid.last, DateTime(2026, 11, 8));
    });

    test('a month starting on a Sunday pulls in six days of the month before', () {
      expect(CalendarLogic.monthGrid(DateTime(2026, 2)).first, DateTime(2026, 1, 26));
    });

    test('a month starting on a Monday starts exactly on the 1st', () {
      expect(CalendarLogic.monthGrid(DateTime(2026, 6)).first, DateTime(2026, 6, 1));
    });

    test('rolls over the year end', () {
      final grid = CalendarLogic.monthGrid(DateTime(2026, 12));
      expect(grid.first, DateTime(2026, 11, 30));
      expect(grid.last, DateTime(2027, 1, 10));
    });
  });

  group('entriesByDay', () {
    test('groups tasks by the day of their deadline, earliest first', () {
      final late = _task(description: 'late', deadline: DateTime(2026, 10, 15, 18));
      final early = _task(description: 'early', deadline: DateTime(2026, 10, 15, 9));
      final next = _task(description: 'next', deadline: DateTime(2026, 10, 16, 10));
      final map = _entries([late, next, early]);
      expect(map.keys.toSet(), {DateTime(2026, 10, 15), DateTime(2026, 10, 16)});
      expect(map[DateTime(2026, 10, 15)]!.map((e) => e.task.description), ['early', 'late']);
      expect(map[DateTime(2026, 10, 16)]!.map((e) => e.task.description), ['next']);
    });

    test('ties on the deadline are ordered by title', () {
      final at = DateTime(2026, 10, 15, 12);
      final map = _entries([
        _task(description: 'b', deadline: at),
        _task(description: 'a', deadline: at),
      ]);
      expect(map[DateTime(2026, 10, 15)]!.map((e) => e.task.description), ['a', 'b']);
    });

    test('a finished or cancelled task is removed from the calendar', () {
      final d = DateTime(2026, 10, 15, 12);
      final map = _entries([
        _task(description: 'active', deadline: d),
        _task(description: 'missed', deadline: d, status: 'missed'),
        _task(description: 'done', deadline: d, status: 'completed'),
        _task(description: 'cancelled', deadline: d, status: 'cancelled'),
      ]);
      expect(map[DateTime(2026, 10, 15)]!.map((e) => e.task.description).toSet(),
          {'active', 'missed'});
    });

    test('a finished recurring task disappears entirely, repeats included', () {
      final map = _entries([
        _task(
          deadline: DateTime(2026, 10, 15, 10),
          recurring: true,
          frequency: 'daily',
          status: 'completed',
        ),
      ]);
      expect(map, isEmpty);
    });

    test('an end-of-day deadline stays on its own day', () {
      final map = _entries([_task(deadline: DateTime(2026, 10, 15, 23, 59, 59))]);
      expect(map.keys.single, DateTime(2026, 10, 15));
    });

    test('a task with no deadline is not drawn (every task is meant to have one)', () {
      expect(_entries([_task()]), isEmpty);
    });

    test('a plain task has one entry whose due time is its deadline', () {
      final t = _task(deadline: DateTime(2026, 10, 20, 18, 30));
      final entry = _entries([t])[DateTime(2026, 10, 20)]!.single;
      expect(entry.task, same(t));
      expect(entry.due, DateTime(2026, 10, 20, 18, 30));
    });
  });

  group('entriesByDay with recurring tasks', () {
    test('daily: appears on every day from its deadline to the end of the range', () {
      final map = _entries([
        _task(deadline: DateTime(2026, 10, 15, 10), recurring: true, frequency: 'daily'),
      ]);
      expect(map.length, 25); // 15 Oct .. 8 Nov
      expect(map.containsKey(DateTime(2026, 10, 15)), isTrue);
      expect(map.containsKey(DateTime(2026, 11, 8)), isTrue);
      expect(map.containsKey(DateTime(2026, 10, 14)), isFalse);
    });

    test('weekly: the same weekday each week', () {
      final map = _entries([
        _task(deadline: DateTime(2026, 10, 15, 10), recurring: true, frequency: 'weekly'),
      ]);
      expect(map.keys.toSet(), {
        DateTime(2026, 10, 15),
        DateTime(2026, 10, 22),
        DateTime(2026, 10, 29),
        DateTime(2026, 11, 5),
      });
    });

    test('monthly: the same date each month, shortened in short months', () {
      final map = _entries(
        [_task(deadline: DateTime(2026, 10, 31, 10), recurring: true, frequency: 'monthly')],
        rangeStart: DateTime(2026, 10, 1),
        rangeEnd: DateTime(2026, 12, 31),
      );
      expect(map.keys.toSet(), {
        DateTime(2026, 10, 31),
        DateTime(2026, 11, 30),
        DateTime(2026, 12, 31),
      });
    });

    test('yearly: the same date next year', () {
      final map = _entries(
        [_task(deadline: DateTime(2026, 10, 20, 10), recurring: true, frequency: 'yearly')],
        rangeStart: DateTime(2027, 10, 1),
        rangeEnd: DateTime(2027, 11, 1),
      );
      expect(map.containsKey(DateTime(2027, 10, 20)), isTrue);
    });

    test('each repeat carries its own due time', () {
      final map = _entries([
        _task(deadline: DateTime(2026, 10, 15, 10), recurring: true, frequency: 'daily'),
      ]);
      expect(map[DateTime(2026, 10, 16)]!.single.due, DateTime(2026, 10, 16, 10));
    });

    test('an old recurring task does not paint chips on past days: only its own deadline and repeats from today', () {
      final map = _entries([
        _task(deadline: DateTime(2026, 10, 1, 10), recurring: true, frequency: 'daily'),
      ]);
      expect(map.containsKey(DateTime(2026, 10, 1)), isTrue); // its overdue deadline
      for (var day = 2; day <= 14; day++) {
        expect(map.containsKey(DateTime(2026, 10, day)), isFalse, reason: 'Oct $day');
      }
      expect(map.containsKey(DateTime(2026, 10, 15)), isTrue); // today
    });

    test('recurring with no frequency chosen does not repeat', () {
      final map = _entries([_task(deadline: DateTime(2026, 10, 15, 10), recurring: true)]);
      expect(map.length, 1);
    });
  });

  group('habitColorIndex', () {
    test('no habit gets -1 (neutral colour)', () {
      expect(CalendarLogic.habitColorIndex(null, 8), -1);
    });

    test('a habit always gets the same colour, wrapping around the palette', () {
      expect(CalendarLogic.habitColorIndex(3, 8), 3);
      expect(CalendarLogic.habitColorIndex(11, 8), 3);
      expect(CalendarLogic.habitColorIndex(3, 8), CalendarLogic.habitColorIndex(3, 8));
      expect(CalendarLogic.habitColorIndex(-3, 8), 3);
    });

    test('an empty palette gives -1 instead of dividing by zero', () {
      expect(CalendarLogic.habitColorIndex(2, 0), -1);
    });
  });

  group('spanLabel', () {
    test('minutes, hours, days', () {
      expect(CalendarLogic.spanLabel(const Duration(seconds: 30)), 'less than a minute');
      expect(CalendarLogic.spanLabel(const Duration(minutes: 45)), '45 min');
      expect(CalendarLogic.spanLabel(const Duration(minutes: 60)), '1 h');
      expect(CalendarLogic.spanLabel(const Duration(minutes: 90)), '1 h 30 min');
      expect(CalendarLogic.spanLabel(const Duration(hours: 23, minutes: 59)), '23 h 59 min');
      expect(CalendarLogic.spanLabel(const Duration(hours: 24)), '1 day');
      expect(CalendarLogic.spanLabel(const Duration(hours: 28)), '1 day 4 h');
      expect(CalendarLogic.spanLabel(const Duration(hours: 72)), '3 days');
    });

    test('a negative span reads the same as a positive one', () {
      expect(CalendarLogic.spanLabel(const Duration(hours: -5)), '5 h');
    });
  });

  group('deadlineText', () {
    test('future deadline: time until', () {
      final t = _task(deadline: DateTime(2026, 10, 17, 18));
      expect(CalendarLogic.deadlineText(t, now), 'Due in 2 days 4 h');
    });

    test('past deadline: how long overdue', () {
      final t = _task(deadline: DateTime(2026, 10, 15, 12));
      expect(CalendarLogic.deadlineText(t, now), 'Overdue by 2 h');
    });

    test('a missed task still reads as overdue (and is still completable)', () {
      final t = _task(status: 'missed', deadline: DateTime(2026, 10, 14, 14));
      expect(CalendarLogic.deadlineText(t, now), 'Overdue by 1 day');
    });

    test('completed and cancelled tasks do not count down', () {
      final d = DateTime(2026, 10, 17);
      expect(CalendarLogic.deadlineText(_task(status: 'completed', deadline: d), now), 'Completed');
      expect(CalendarLogic.deadlineText(_task(status: 'cancelled', deadline: d), now), 'Cancelled');
    });

    test('no deadline', () {
      expect(CalendarLogic.deadlineText(_task(), now), 'No deadline');
    });
  });

  group('snippet', () {
    test('has the three lines the calendar shows: time left, subtasks, difficulty', () {
      final t = _task(
        description: 'Essay',
        deadline: DateTime(2026, 10, 17, 18),
        difficulty: 'hard',
        subtasks: List.generate(5, (i) => Subtask(text: 's$i', isDone: i < 2)),
      );
      final s = CalendarLogic.snippet(t, now);
      expect(s.title, 'Essay');
      expect(s.deadlineText, 'Due in 2 days 4 h');
      expect(s.subtaskText, '2 of 5 subtasks');
      expect(s.difficultyText, 'Hard');
    });

    test('a recurring repeat is timed from its own due moment, not the task deadline', () {
      final t = _task(deadline: DateTime(2026, 10, 15, 10), recurring: true, frequency: 'daily');
      final s = CalendarLogic.snippet(t, now, due: DateTime(2026, 10, 16, 10));
      expect(s.deadlineText, 'Due in 20 h');
    });

    test('a task with no subtasks says so', () {
      final s = CalendarLogic.snippet(_task(deadline: DateTime(2026, 10, 17)), now);
      expect(s.subtaskText, 'No subtasks');
    });

    test('an empty description is shown as untitled', () {
      expect(CalendarLogic.snippet(_task(description: ''), now).title, '(untitled task)');
    });
  });
}
