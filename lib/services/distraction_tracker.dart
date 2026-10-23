import 'package:flutter/material.dart';

//automatic distraction tracking feature
//increasing counter as user leaves app while in focus pond

class DistractionTrackerService with WidgetsBindingObserver {
  final VoidCallback onDistractionDetected;
  bool _tracking = false;
  int _distractions = 0;

  int get distractions => _distractions;

  DistractionTrackerService({required this.onDistractionDetected});

  void initialize() {
    _tracking = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    _tracking = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  void reset() {
    _distractions = 0;
  }

  void updateTimerStatus(bool running) {
    _tracking = running;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_tracking) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _distractions++;
      onDistractionDetected();
    }
  }
}
