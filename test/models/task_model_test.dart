import 'package:flutter_test/flutter_test.dart';
import 'package:actiphibian/models/task.dart';

Task _base() => Task(
      id: 1,
      description: 'Essay',
      recurring: true,
      recurrenceFrequency: 'weekly',
      difficulty: 'hard',
      deadline: DateTime(2026, 10, 20, 18),
      durationMinutes: 45,
      habitId: 3,
    );

void main() {
  group('copyWith keeps what is not mentioned', () {
    test('leaving habit, deadline, duration and frequency out keeps them', () {
      final t = _base().copyWith(description: 'New title');
      expect(t.description, 'New title');
      expect(t.habitId, 3);
      expect(t.deadline, DateTime(2026, 10, 20, 18));
      expect(t.durationMinutes, 45);
      expect(t.recurrenceFrequency, 'weekly');
    });
  });

  group('copyWith with an explicit null clears the field', () {
    test('habit', () => expect(_base().copyWith(habitId: null).habitId, isNull));
    test('duration', () => expect(_base().copyWith(durationMinutes: null).durationMinutes, isNull));
    test('deadline', () => expect(_base().copyWith(deadline: null).deadline, isNull));
    test('frequency',
        () => expect(_base().copyWith(recurrenceFrequency: null).recurrenceFrequency, isNull));

    test('and a value sets it', () {
      final t = _base().copyWith(habitId: 7, recurrenceFrequency: 'daily');
      expect(t.habitId, 7);
      expect(t.recurrenceFrequency, 'daily');
    });
  });

  test('isRecurring needs both the flag and a frequency', () {
    expect(_base().isRecurring, isTrue);
    expect(_base().copyWith(recurrenceFrequency: null).isRecurring, isFalse);
    expect(_base().copyWith(recurring: false).isRecurring, isFalse);
  });

  test('toMap and fromMap keep the habit and recurrence', () {
    final copy = Task.fromMap(_base().toMap());
    expect(copy.habitId, 3);
    expect(copy.recurring, isTrue);
    expect(copy.recurrenceFrequency, 'weekly');
    expect(copy.deadline, DateTime(2026, 10, 20, 18));
    expect(copy.durationMinutes, 45);
  });

  test('a task with no habit or recurrence round-trips as null', () {
    final plain = Task(description: 'x', recurring: false, difficulty: 'easy');
    final copy = Task.fromMap(plain.toMap());
    expect(copy.habitId, isNull);
    expect(copy.recurrenceFrequency, isNull);
  });
}
