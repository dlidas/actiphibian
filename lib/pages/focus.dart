import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FocusPage(),
  ));
}

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  // Focus timer duration state
  int _minutes = 20;
  int _seconds = 0;
  int _secondsRemaining = 1200; // 20 minutes default
  Timer? _timer;
  bool _isRunning = false;

  // Distraction tracking
  int _distractions = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Set Focus Timer Dialog (The Middle Wireframe Page)
  Future<void> _showSetFocusTimerDialog() async {
    TextEditingController minController =
        TextEditingController(text: _minutes.toString().padLeft(2, '0'));
    TextEditingController secController =
        TextEditingController(text: _seconds.toString().padLeft(2, '0'));

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
                          _secondsRemaining = (parsedMins * 60) + parsedSecs;
                        });

                        Navigator.pop(context);
                      },
                      child: const Text('OK', style: TextStyle(color: Colors.white)),
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
      setState(() => _isRunning = false);
    } else {
      if (_secondsRemaining <= 0) {
        _secondsRemaining = (_minutes * 60) + _seconds;
      }
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _timer?.cancel();
          setState(() => _isRunning = false);
        }
      });
    }
  }

  void _logDistraction() {
    if (_isRunning) {
      setState(() => _distractions++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Distraction logged! Total: $_distractions'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  String _formattedTime() {
    int m = _secondsRemaining ~/ 60;
    int s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Pond'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Distractions: $_distractions',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                _formattedTime(),
                style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Button to trigger the Set Focus Timer dialog
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8CC63F),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _showSetFocusTimerDialog,
                icon: const Icon(Icons.edit_calendar, color: Colors.white),
                label: const Text(
                  'Set Focus Timer',
                  style: TextStyle(color: Colors.white, fontSize: 16),
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
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isRunning ? _logDistraction : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Log Distraction', style: TextStyle(color: Colors.white)),
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
