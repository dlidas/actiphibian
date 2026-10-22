import 'package:flutter/material.dart';
import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/models/habit.dart';
import 'package:actiphibian/models/task.dart';
import 'package:actiphibian/widgets/task_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Task> _tasks = const [];
  List<Habit> _habits = const [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final tasks = await LocalDb.getTasks();
      final habits = await LocalDb.getHabits();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _habits = habits;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Could not load calendar data: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadCalendarData,
            tooltip: 'Refresh calendar',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load tasks for the calendar.'),
                      const SizedBox(height: 8),
                      Text(_loadError!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCalendarData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : TaskCalendar(tasks: _tasks, habits: _habits),
      ),
    );
  }
}
