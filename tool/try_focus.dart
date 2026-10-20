// ignore_for_file: avoid_print
// Am checking to see if even without the focus timer page wired yet, does the suer still earn xp when using a timer
// Making alot of assumptions but am just checking to see if my code logic makes sense. 

import 'package:actiphibian/models/focus_session.dart';
import 'package:actiphibian/services/focus_xp.dart';
import 'package:actiphibian/services/study_methods.dart';

void main() {
  final sessions = <FocusSession>[];
  final day = DateTime(2026, 10, 18, 9);
  for (var i = 0; i < 6; i++) {
    final today = FocusXp.focusMinutesOnDay(sessions, day);
    final xp = FocusXp.xpForSession(
      method: StudyMethods.pomodoro,
      focusedMinutes: 25,
      focusMinutesToday: today,
    );
    sessions.add(FocusSession(
        methodId: 'pomodoro', startedAt: day, focusedMinutes: 25, xpAwarded: xp));
    print('25-min session #${i + 1}: $xp XP (minutes already today: $today)');
  }
  print('Timer opens with: ${StudyMethods.methodForTimer(recommendedId: 'eat_that_frog').name}');
  print('Skipped questionnaire: ${StudyMethods.methodForTimer().name}');
}