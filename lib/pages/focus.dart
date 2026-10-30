import 'package:actiphibian/data/user_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/focus_session_controller.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  bool _showingRewardDialog = false;

  FocusSessionController get _session =>
      context.read<FocusSessionController>();

  // Set Focus Timer Dialog (The Middle Wireframe Page)
  Future<void> _showSetFocusTimerDialog() async {
    TextEditingController minController = TextEditingController(
      text: _session.minutes.toString().padLeft(2, '0'),
    );
    TextEditingController secController = TextEditingController(
      text: _session.seconds.toString().padLeft(2, '0'),
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.secondary,
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
                    color: Theme.of(context).colorScheme.primary,
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        int parsedMins = int.tryParse(minController.text) ?? 0;
                        int parsedSecs = int.tryParse(secController.text) ?? 0;

                        _session.setDuration(parsedMins, parsedSecs);

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
    _session.toggle(context.read<UserManager>());
  }

  Future<void> _confirmEndSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End this session?'),
        content: const Text(
          'The timer will reset and you will not earn XP or coins for this session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('End session'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _session.endSession();
  }

  //Show the reward dialog once, when this page is visible
  void _showPendingReward(FocusReward? reward) {
    if (reward == null || _showingRewardDialog) return;
    _showingRewardDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _showingRewardDialog = false;
        return;
      }
      _showAwardDialog(reward.xp, reward.coins, reward.distractions);
    });
  }

  void _showAwardDialog(int xpEarned, int coinsEarned, int distractions) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.secondary,
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
              if (distractions > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Distractions logged: $distractions',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                _showingRewardDialog = false;
                Navigator.of(dialogContext).pop();

                _session.claimReward();
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

  String _formattedTime(int secondsRemaining) {
    int m = secondsRemaining ~/ 60;
    int s = secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserManager>().user;
    final session = context.watch<FocusSessionController>();
    _showPendingReward(session.pendingReward);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      Icons.bolt,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: 18,
                    ),
                    label: Text(
                      '${user.xp} XP earned',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  Chip(
                    avatar: Icon(
                      Icons.monetization_on,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: 18,
                    ),
                    label: Text(
                      '${user.balance} coins',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Chip(
                label: Text(
                  'Auto Distractions: ${session.distractions}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: const Color(0xFFE1F9B9),
              ),
              const SizedBox(height: 20),
              Text(
                _formattedTime(session.secondsRemaining),
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Button to trigger the Set Focus Timer dialog
              Tooltip(
                message: !session.hasActiveSession
                    ? 'Set the focus timer'
                    : 'Timer settings are locked until this session ends',
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: !session.hasActiveSession
                      ? _showSetFocusTimerDialog
                      : null,
                  label: const Text('Set Focus Timer'),
                  icon: const Icon(Icons.edit_calendar),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _toggleTimer,
                    child: Text(session.isRunning ? 'Pause' : 'Start'),
                  ),
                  if (session.hasActiveSession) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _confirmEndSession,
                      child: const Text('End'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
