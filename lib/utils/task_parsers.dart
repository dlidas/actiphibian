import '../models/task.dart';
/// Still a work in progress. I have no way to check if the parsing is working as intended until the UI design is done.
/// Will update with the calander feature integrated in the task screen.
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
    if (raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }
  static String formatDeadline(DateTime? date) {
    if (date == null) return 'No deadline';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
