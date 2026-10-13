import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Writes to a real file in the app's private documents directory —
/// this should work theorotically but I haven't tested it yet on the Android emulator.
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
  /// Call logTaskCreated and print() in the debug console.
  static Future<String> readLog() async {
    final file = await _getLogFile();
    if (!await file.exists()) return '(no tasks logged yet)';
    return await file.readAsString();
  }

 /// Log clear
  static Future<void> clearLog() async {
    final file = await _getLogFile();
    if (await file.exists()) await file.delete();
  }
}
