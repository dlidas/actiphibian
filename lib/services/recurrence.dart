/// A recurring task keeps its next due date as its deadline. Completing it records the completion
/// and creates the next occurrence as a new task, so each completion earns its own XP.
/// Cancelling or deleting it ends the series.
class Recurrence {
  static const List<String> frequencies = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  static String label(String? frequency) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return 'Never';
    }
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// The n-th repeat after anchor (0 is the anchor itself), always counted from the anchor so a
  /// monthly task on the 31st gives Jan 31, Feb 28, Mar 31 instead of drifting to the 28th.
  static DateTime occurrenceAt(DateTime anchor, String frequency, int n) {
    switch (frequency) {
      case 'daily':
        return DateTime(
          anchor.year,
          anchor.month,
          anchor.day + n,
          anchor.hour,
          anchor.minute,
          anchor.second,
        );
      case 'weekly':
        return DateTime(
          anchor.year,
          anchor.month,
          anchor.day + 7 * n,
          anchor.hour,
          anchor.minute,
          anchor.second,
        );
      case 'monthly':
        final monthIndex = anchor.month - 1 + n;
        final year = anchor.year + monthIndex ~/ 12;
        final month = monthIndex % 12 + 1;
        final day = anchor.day < _daysInMonth(year, month)
            ? anchor.day
            : _daysInMonth(year, month);
        return DateTime(
          year,
          month,
          day,
          anchor.hour,
          anchor.minute,
          anchor.second,
        );
      case 'yearly':
        final year = anchor.year + n;
        final day = anchor.day < _daysInMonth(year, anchor.month)
            ? anchor.day
            : _daysInMonth(year, anchor.month);
        return DateTime(
          year,
          anchor.month,
          day,
          anchor.hour,
          anchor.minute,
          anchor.second,
        );
      default:
        throw ArgumentError.value(
          frequency,
          'frequency',
          'unknown recurrence frequency',
        );
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The first repeat whose date is after both the due date and the completion date: no second one
  /// due today, nothing re-scheduled when finished early, no backlog when left for weeks.
  static DateTime nextAfterCompletion({
    required DateTime deadline,
    required String frequency,
    required DateTime completedAt,
  }) {
    final later = completedAt.isAfter(deadline) ? completedAt : deadline;
    final threshold = _dateOnly(later);
    var n = 1;
    var next = occurrenceAt(deadline, frequency, n);
    while (!_dateOnly(next).isAfter(threshold)) {
      n++;
      next = occurrenceAt(deadline, frequency, n);
    }
    return next;
  }
}
