import 'package:flutter_test/flutter_test.dart';
import 'package:actiphibian/services/task_form_validator.dart';

void main() {
  final now = DateTime(2026, 10, 18, 12);
  final future = DateTime(2026, 10, 20, 18);

  TaskFormErrors check({
    String description = 'Essay',
    DateTime? deadline,
    bool recurring = false,
    String? frequency,
    bool checkPast = true,
  }) {
    return TaskFormValidator.validate(
      description: description,
      deadline: deadline,
      recurring: recurring,
      frequency: frequency,
      now: now,
      checkPast: checkPast,
    );
  }

  test('a description and a future deadline are enough', () {
    expect(check(deadline: future).hasErrors, isFalse);
  });

  group('description is required', () {
    test('empty or only spaces is refused', () {
      expect(check(description: '', deadline: future).description, isNotNull);
      expect(check(description: '   ', deadline: future).description, isNotNull);
    });
  });

  group('deadline is required for an ordinary task', () {
    test('missing is refused', () {
      final e = check();
      expect(e.deadline, 'Pick a deadline');
      expect(e.hasErrors, isTrue);
    });

    test('a deadline that has already passed is refused', () {
      expect(check(deadline: DateTime(2026, 10, 18, 11)).deadline, isNotNull);
      expect(check(deadline: DateTime(2026, 10, 10)).deadline, isNotNull);
    });

    test('right now is not yet past, a minute ago is', () {
      expect(check(deadline: DateTime(2026, 10, 18, 12, 0, 1)).deadline, isNull);
      expect(check(deadline: DateTime(2026, 10, 18, 11, 59)).deadline, isNotNull);
    });

    test('an old deadline is accepted when the check is off (editing something else on an overdue task)', () {
      expect(check(deadline: DateTime(2026, 10, 10), checkPast: false).hasErrors, isFalse);
    });
  });

  group('a recurring task needs a frequency, not a deadline', () {
    test('recurring with a frequency and no deadline is fine', () {
      expect(check(recurring: true, frequency: 'weekly').hasErrors, isFalse);
    });

    test('recurring with no frequency is refused', () {
      final e = check(recurring: true, deadline: future);
      expect(e.frequency, isNotNull);
      expect(e.deadline, isNull);
    });

    test('a first-due time in the past is still refused', () {
      final e = check(recurring: true, frequency: 'daily', deadline: DateTime(2026, 10, 1));
      expect(e.deadline, contains('first-due'));
    });

    test('a frequency is ignored on a task that is not recurring', () {
      expect(check(deadline: future, frequency: 'daily').hasErrors, isFalse);
    });
  });

  test('every problem is reported at once', () {
    final e = check(description: '', recurring: true);
    expect(e.description, isNotNull);
    expect(e.frequency, isNotNull);
    expect(e.hasErrors, isTrue);
  });

  test('habit, subtasks and duration are not validated: they are optional', () {
    expect(check(deadline: future).hasErrors, isFalse);
  });
}
