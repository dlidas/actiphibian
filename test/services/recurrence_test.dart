import 'package:flutter_test/flutter_test.dart';
import 'package:actiphibian/services/recurrence.dart';

void main() {
  group('occurrenceAt', () {
    final anchor = DateTime(2026, 10, 15, 10, 30);

    test('n = 0 is the anchor itself', () {
      for (final f in Recurrence.frequencies) {
        expect(Recurrence.occurrenceAt(anchor, f, 0), anchor, reason: f);
      }
    });

    test('daily and weekly add days', () {
      expect(Recurrence.occurrenceAt(anchor, 'daily', 3), DateTime(2026, 10, 18, 10, 30));
      expect(Recurrence.occurrenceAt(anchor, 'weekly', 2), DateTime(2026, 10, 29, 10, 30));
    });

    test('monthly keeps the date, and rolls over the year', () {
      final nov = DateTime(2026, 11, 15, 9);
      expect(Recurrence.occurrenceAt(nov, 'monthly', 3), DateTime(2027, 2, 15, 9));
      expect(Recurrence.occurrenceAt(nov, 'monthly', 14), DateTime(2028, 1, 15, 9));
    });

    test('monthly on the 31st uses the last day of shorter months, without drifting', () {
      final jan31 = DateTime(2026, 1, 31, 8);
      expect(Recurrence.occurrenceAt(jan31, 'monthly', 1), DateTime(2026, 2, 28, 8));
      expect(Recurrence.occurrenceAt(jan31, 'monthly', 2), DateTime(2026, 3, 31, 8));
      expect(Recurrence.occurrenceAt(jan31, 'monthly', 3), DateTime(2026, 4, 30, 8));
      expect(Recurrence.occurrenceAt(jan31, 'monthly', 13), DateTime(2027, 2, 28, 8));
    });

    test('monthly Feb 29 exists in a leap year', () {
      expect(Recurrence.occurrenceAt(DateTime(2028, 1, 31, 8), 'monthly', 1),
          DateTime(2028, 2, 29, 8));
    });

    test('yearly keeps the date; 29 February becomes 28 February in other years', () {
      expect(Recurrence.occurrenceAt(DateTime(2026, 10, 20, 12), 'yearly', 1),
          DateTime(2027, 10, 20, 12));
      final leapDay = DateTime(2028, 2, 29, 12);
      expect(Recurrence.occurrenceAt(leapDay, 'yearly', 1), DateTime(2029, 2, 28, 12));
      expect(Recurrence.occurrenceAt(leapDay, 'yearly', 4), DateTime(2032, 2, 29, 12));
    });

    test('keeps the time of day, seconds included', () {
      final endOfDay = DateTime(2026, 10, 15, 23, 59, 59);
      expect(Recurrence.occurrenceAt(endOfDay, 'daily', 1), DateTime(2026, 10, 16, 23, 59, 59));
    });

    test('an unknown frequency is a loud error, not a silent default', () {
      expect(() => Recurrence.occurrenceAt(anchor, 'hourly', 1), throwsArgumentError);
    });
  });

  group('nextAfterCompletion', () {
    test('daily, finished on the day: due again tomorrow at the same time', () {
      final next = Recurrence.nextAfterCompletion(
        deadline: DateTime(2026, 10, 18, 18),
        frequency: 'daily',
        completedAt: DateTime(2026, 10, 18, 10),
      );
      expect(next, DateTime(2026, 10, 19, 18));
    });

    test('daily, finished late on the same day: still tomorrow, never another one today', () {
      final next = Recurrence.nextAfterCompletion(
        deadline: DateTime(2026, 10, 18, 18),
        frequency: 'daily',
        completedAt: DateTime(2026, 10, 18, 20),
      );
      expect(next, DateTime(2026, 10, 19, 18));
    });

    test('finished early: the repeat that was already done is not scheduled again', () {
      final next = Recurrence.nextAfterCompletion(
        deadline: DateTime(2026, 10, 18, 18),
        frequency: 'daily',
        completedAt: DateTime(2026, 10, 16, 9),
      );
      expect(next, DateTime(2026, 10, 19, 18));
    });

    test('left for a week: no backlog, the next one is after the completion day', () {
      final next = Recurrence.nextAfterCompletion(
        deadline: DateTime(2026, 10, 18, 18),
        frequency: 'daily',
        completedAt: DateTime(2026, 10, 25, 10),
      );
      expect(next, DateTime(2026, 10, 26, 18));
    });

    test('weekly', () {
      expect(
        Recurrence.nextAfterCompletion(
          deadline: DateTime(2026, 10, 15, 9),
          frequency: 'weekly',
          completedAt: DateTime(2026, 10, 15, 8),
        ),
        DateTime(2026, 10, 22, 9),
      );
      expect(
        Recurrence.nextAfterCompletion(
          deadline: DateTime(2026, 10, 15, 9),
          frequency: 'weekly',
          completedAt: DateTime(2026, 10, 30, 8),
        ),
        DateTime(2026, 11, 5, 9),
      );
    });

    test('monthly and yearly', () {
      expect(
        Recurrence.nextAfterCompletion(
          deadline: DateTime(2026, 1, 31, 8),
          frequency: 'monthly',
          completedAt: DateTime(2026, 1, 31, 7),
        ),
        DateTime(2026, 2, 28, 8),
      );
      expect(
        Recurrence.nextAfterCompletion(
          deadline: DateTime(2026, 10, 20, 12),
          frequency: 'yearly',
          completedAt: DateTime(2026, 10, 20, 11),
        ),
        DateTime(2027, 10, 20, 12),
      );
    });
  });

  test('labels', () {
    expect(Recurrence.label('daily'), 'Daily');
    expect(Recurrence.label('weekly'), 'Weekly');
    expect(Recurrence.label('monthly'), 'Monthly');
    expect(Recurrence.label('yearly'), 'Yearly');
    expect(Recurrence.label(null), 'Never');
  });
}
