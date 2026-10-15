import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
    final line = '[$timestamp] title="$title" | subtasks="$subtasksRaw" '
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
