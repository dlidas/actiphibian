import 'dart:async';
import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/data/user_manager.dart';
import 'package:actiphibian/models/focus_session.dart';
import 'package:actiphibian/services/user_progress.dart';
import 'package:flutter/foundation.dart';
import 'distraction_tracker.dart';
import 'focus_xp.dart';

//Rewards to show once a focus session completes
class FocusReward {
  final int xp;
  final int coins;
  final int distractions;

  const FocusReward({
    required this.xp,
    required this.coins,
    required this.distractions,
  });
}

//Holds the focus timer above the page, so a running session survives
//switching tabs
class FocusSessionController extends ChangeNotifier {
  late final DistractionTrackerService _tracker;

  // Focus timer duration state
  int _minutes = 20;
  int _seconds = 0;
  int _secondsRemaining = 1200; // 20 minutes default
  int _focusedSeconds = 0;
  int _initialSessionMinutes = 20; // Tracks starting time for Ovayo's calculation
  Timer? _timer;
  bool _isRunning = false;
  bool _isCompleting = false;

  // Distraction tracking
  int _distractions = 0;
  DateTime? _sessionStartedAt;

  FocusReward? _pendingReward;

  FocusSessionController() {
    _tracker = DistractionTrackerService(
      onDistractionDetected: () {
        _distractions = _tracker.distractions;
        notifyListeners();
      },
    );
  }

  int get minutes => _minutes;
  int get seconds => _seconds;
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  bool get hasActiveSession => _sessionStartedAt != null;
  int get distractions => _distractions;
  FocusReward? get pendingReward => _pendingReward;

  void setDuration(int minutes, int seconds) {
    _minutes = minutes;
    _seconds = seconds;
    _initialSessionMinutes = minutes > 0 ? minutes : 1;
    _secondsRemaining = (minutes * 60) + seconds;
    notifyListeners();
  }

  void toggle(UserManager userManager) {
    if (_isRunning) {
      _timer?.cancel();
      _tracker.dispose();
      _isRunning = false;
      notifyListeners();
      return;
    }

    if (_secondsRemaining <= 0) {
      _secondsRemaining = (_minutes * 60) + _seconds;
    }
    if (_sessionStartedAt == null) {
      _focusedSeconds = 0;
      // Keep the count across pause and resume within one session
      _tracker.reset();
      _distractions = 0;
    }
    _sessionStartedAt ??= DateTime.now();

    _tracker.initialize();

    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        _focusedSeconds++;
        notifyListeners();
      } else {
        timer.cancel();
        _isRunning = false;
        notifyListeners();
        _onTimerCompleted(userManager);
      }
    });
  }

  // Triggered automatically when the timer finishes
  Future<void> _onTimerCompleted(UserManager userManager) async {
    if (_isCompleting) return;
    _isCompleting = true;

    // Stop distraction tracking when timer completes
    _tracker.dispose();

    final startedAt = _sessionStartedAt ?? DateTime.now();
    _sessionStartedAt = null;
    final focusedMinutes = _focusedSeconds ~/ 60;
    final effectiveMinutes =
        focusedMinutes > 0 ? focusedMinutes : _initialSessionMinutes;

    try {
      final sessions = await LocalDb.getFocusSessions();
      final earnedXP = FocusXp.xpForSession(
        focusedMinutes: effectiveMinutes,
        focusMinutesToday: FocusXp.focusMinutesOnDay(sessions, startedAt),
      );

      final session = FocusSession(
        methodId: 'timer',
        startedAt: startedAt,
        focusedMinutes: effectiveMinutes,
        xpAwarded: earnedXP,
      );
      await LocalDb.addFocusSession(session);

      final tasks = await LocalDb.getTasks();
      final progress = UserProgress.fromTasks(
        tasks,
        now: DateTime.now(),
        focusSessions: [...sessions, session],
      );

      final previousBalance = userManager.user.balance;
      userManager.updateProgress(
        level: progress.level,
        xp: progress.totalXp,
        balance: progress.coins,
      );

      final earnedCoins = progress.coins - previousBalance;
      final earnedCoinsSafe =
          earnedCoins > 0 ? earnedCoins : (earnedXP / 10).floor();
      _pendingReward = FocusReward(
        xp: earnedXP,
        coins: earnedCoinsSafe,
        distractions: _distractions,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not save focus session rewards: $error');
      debugPrintStack(stackTrace: stackTrace);

      // Fallback display
      final earnedXP = FocusXp.xpForSession(
        focusedMinutes: _initialSessionMinutes,
        focusMinutesToday: 0,
      );
      _pendingReward = FocusReward(
        xp: earnedXP,
        coins: (earnedXP / 10).floor(),
        distractions: _distractions,
      );
    }
    _isCompleting = false;
    notifyListeners();
  }

  //Stops the session early without saving it or awarding XP
  void endSession() {
    _timer?.cancel();
    _tracker.dispose();
    _tracker.reset();
    _sessionStartedAt = null;
    _focusedSeconds = 0;
    _secondsRemaining = (_minutes * 60) + _seconds;
    _isRunning = false;
    _distractions = 0;
    notifyListeners();
  }

  //Called when the user closes the reward dialog
  void claimReward() {
    _pendingReward = null;
    _tracker.reset();
    _secondsRemaining = (_minutes * 60) + _seconds;
    _isRunning = false;
    _distractions = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tracker.dispose();
    super.dispose();
  }
}
