import '../models/task.dart';

class TaskParsers {
  static List<Subtask> parseSubtasks(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((text) => Subtask(text: text))
        .toList();
  }

  static String formatSubtasksForEditing(List<Subtask> subtasks) =>
      subtasks.map((s) => s.text).join(', ');

  static int? parseDuration(String raw) {
    if (raw.trim().isEmpty) return null;
    return int.tryParse(raw.trim());
  }

  static DateTime? parseDeadline(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    final dateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text);
    if (!dateOnly) return parsed;
    return DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
  }

  static String formatDeadline(DateTime? date) {
    if (date == null) return 'No deadline';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
