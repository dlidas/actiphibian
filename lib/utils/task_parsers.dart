class TaskParsers {
  static List<String> parseSubtasks(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
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
