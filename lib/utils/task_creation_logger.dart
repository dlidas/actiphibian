import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Quick, no-database way to SEE that the Add Task flow is capturing the
/// right values end to end, before SQLite is wired in. Call logTaskCreated() right where you currently build/save new task.
/// Writes to a real file in the app's private documents directory. This works on the Android emulator
class TaskCreationLogger {
  static Future<File> _getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/task_creation_log.txt');
  }

  static Future<void> logTaskCreated({
    required String title,
    String subtasksRaw = '',
    String durationRaw = '',
    String deadlineRaw = '',
    required bool isRecurring,
    required String difficulty,
  }) async {
    final file = await _getLogFile();
    final timestamp = DateTime.now().toIso8601String();
    final line =
        '[$timestamp] title="$title" | subtasks="$subtasksRaw" '
        '| duration="$durationRaw" | deadline="$deadlineRaw" '
        '| recurring=$isRecurring | difficulty=$difficulty\n';
    await file.writeAsString(line, mode: FileMode.append);
  }

  static Future<String> readLog() async {
    final file = await _getLogFile();
    if (!await file.exists()) return '(no tasks logged yet)';
    return await file.readAsString();
  }

  static Future<void> clearLog() async {
    final file = await _getLogFile();
    if (await file.exists()) await file.delete();
  }
}
