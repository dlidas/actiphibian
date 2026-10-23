import 'dart:async';
import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/data/userManager.dart';
import 'package:actiphibian/models/focus_session.dart';
import 'package:actiphibian/models/user.dart';
import 'package:actiphibian/services/user_progress.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/focus_xp.dart';
import '../widgets/user_stats_app_bar.dart';
import '../services/distraction_tracker.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  // Instance of distraction tracker
  late final DistractionTrackerService _tracker;

  // Focus timer duration state
  int _minutes = 20;
  int _seconds = 0;
  int _secondsRemaining = 1200; // 20 minutes default
  int _focusedSeconds = 0;
  int _initialSessionMinutes = 20; // Tracks starting time for Ovayo's calculation
  Timer? _timer;
  bool _isRunning = false;
  bool _showingRewardDialog = false;

  // Distraction tracking
  int _distractions = 0;
  DateTime? _sessionStartedAt;

  @override
  void dispose() {
    _timer?.cancel();
    _tracker.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tracker = DistractionTrackerService(
      onDistractionDetected: () {
        setState(() {
          _distractions = _tracker.distractions;
        });
      },
    );
  }

  // Set Focus Timer Dialog (The Middle Wireframe Page)
  Future<void> _showSetFocusTimerDialog() async {
    TextEditingController minController = TextEditingController(
      text: _minutes.toString().padLeft(2, '0'),
    );
    TextEditingController secController = TextEditingController(
      text: _seconds.toString().padLeft(2, '0'),
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFE5F8B8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8CC63F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'Set Focus Timer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Interactive Minutes : Seconds Input Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD3EFA1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: secController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons: Cancel & OK
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8CC63F),
                      ),
                      onPressed: () {
                        int parsedMins = int.tryParse(minController.text) ?? 0;
                        int parsedSecs = int.tryParse(secController.text) ?? 0;

                        setState(() {
                          _minutes = parsedMins;
                          _seconds = parsedSecs;
                          _initialSessionMinutes = parsedMins > 0
                              ? parsedMins
                              : 1;
                          _secondsRemaining = (parsedMins * 60) + parsedSecs;
                        });

                        Navigator.pop(context);
                      },
                      child: const Text(
                        'OK',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _tracker.dispose();
      setState(() => _isRunning = false);
    } else {
      if (_secondsRemaining <= 0) {
        _secondsRemaining = (_minutes * 60) + _seconds;
      }
      if (_sessionStartedAt == null) {
        _focusedSeconds = 0;
      }
      _sessionStartedAt ??= DateTime.now();

      _tracker.reset();
      _tracker.initialize();

      _isRunning = true;

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
            _focusedSeconds++;
          });
        } else {
          timer.cancel();
          setState(() => _isRunning = false);
          _onTimerCompleted();
        }
      });
    }
  }

  // Triggered automatically when the timer finishes
  Future<void> _onTimerCompleted() async {
    if (_showingRewardDialog) return;
    _showingRewardDialog = true;

    // Stop distraction tracking when timer completes
    _tracker.dispose();

    final startedAt = _sessionStartedAt ?? DateTime.now();
    _sessionStartedAt = null;
    final focusedMinutes = _focusedSeconds ~/ 60;
    final effectiveMinutes = focusedMinutes > 0 ? focusedMinutes : _initialSessionMinutes;

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
      if (!mounted) return;
      
      final currentUser = context.read<UserManager>().user;
      final progress = UserProgress.fromTasks(
        tasks,
        now: DateTime.now(),
        focusSessions: [...sessions, session],
      );
      
      final previousBalance = currentUser.balance;
      context.read<UserManager>().updateProgress(
        level: progress.level,
        xp: progress.totalXp,
        balance: progress.coins,
      );

      final earnedCoins = progress.coins - previousBalance;
      final earnedCoinsSafe = earnedCoins > 0 ? earnedCoins : (earnedXP / 10).floor();

      if (!mounted) return;
      _showAwardDialog(earnedXP, earnedCoinsSafe);
    } catch (error, stackTrace) {
      debugPrint('Could not save focus session rewards: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      
      // Fallback display
      int earnedXP = FocusXp.xpForSession(focusedMinutes: _initialSessionMinutes, focusMinutesToday: 0);
      int earnedCoins = (earnedXP / 10).floor();
      _showAwardDialog(earnedXP, earnedCoins);
    }
  }

  void _showAwardDialog(int xpEarned, int coinsEarned) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE5F8B8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Session Completed!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D3B00),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earned XP: +$xpEarned XP',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Earned Coins: +$coinsEarned Coins',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_distractions > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Distractions logged: $_distractions',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8CC63F),
              ),
              onPressed: () {
                _showingRewardDialog = false;
                Navigator.of(dialogContext).pop();

                setState(() {
                  _secondsRemaining = (_minutes * 60) + _seconds;
                  _isRunning = false;
                  _distractions = 0;
                });
              },
              child: const Text(
                'Claim Rewards',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formattedTime() {
    int m = _secondsRemaining ~/ 60;
    int s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserManager>().user;
    return Scaffold(
      appBar: const UserStatsAppBar(title: 'Focus Pond'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display Live Balances
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    avatar: const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 18,
                    ),
                    label: Text(
                      '${user.balance} Coins',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFFE5F8B8),
                  ),
                  const SizedBox(width: 12),
                  Chip(
                    avatar: const Icon(
                      Icons.bolt,
                      color: Colors.orange,
                      size: 18,
                    ),
                    label: Text(
                      '${user.xp} XP',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFFE5F8B8),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Chip(
                label: Text(
                  'Auto Distractions: $_distractions',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: const Color(0xFFE1F9B9),
              ),
              const SizedBox(height: 20),
              Text(
                _formattedTime(),
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Button to trigger the Set Focus Timer dialog
              Tooltip(
                message: _sessionStartedAt == null
                    ? 'Set the focus timer'
                    : 'Timer settings are locked until this session ends',
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8CC63F),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _sessionStartedAt == null
                      ? _showSetFocusTimerDialog
                      : null,
                  label: const Text(
                    'Set Focus Timer',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  icon: const Icon(Icons.edit_calendar, color: Colors.white),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _toggleTimer,
                    child: Text(_isRunning ? 'Pause' : 'Start'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
