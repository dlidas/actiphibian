//DEPENDENCY
//flutter pub add table_calendar 

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// Imports team's database service for Ovayo's local SQLite DB
import '../data/repo.dart';

/// AppTask model matching Daniel's whiteboard specs
class AppTask {
  final String id;
  final String title;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final int subtaskCount;
  final DateTime deadline;
  final bool isRecurring;

  AppTask({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.subtaskCount,
    required this.deadline,
    this.isRecurring = false,
  });

  /// Factory constructor to parse SQLite Database Map into an AppTask object
  factory AppTask.fromMap(Map<String, dynamic> map) {
    DateTime parsedDeadline = DateTime.now();
    if (map['deadline'] != null) {
      parsedDeadline = DateTime.tryParse(map['deadline'].toString()) ?? DateTime.now();
    }

    return AppTask(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? map['task_name'] ?? 'Untitled Task',
      difficulty: map['difficulty'] ?? 'Medium',
      subtaskCount: map['subtask_count'] ?? map['subtaskCount'] ?? 0,
      deadline: parsedDeadline,
      isRecurring: map['is_recurring'] == 1 || map['isRecurring'] == true,
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  
  // Stores tasks fetched from SQLite, grouped by normalized DateTime (YYYY-MM-DD)
  Map<DateTime, List<AppTask>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasksFromLocalDb();
  }

  /// Normalizes dates to UTC midnight so calendar key matching is 100% accurate
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// OVAYO'S REQUIREMENT: Fetches tasks directly from local SQLite DB
  Future<void> _fetchTasksFromLocalDb() async {
    setState(() => _isLoading = true);

    // try {
    //   // 1. Call Ovayo's DatabaseHelper to query all stored tasks
    //   final dbRows = await LocalDb.getTasks();

    //   Map<DateTime, List<AppTask>> loadedEvents = {};

    //   // 2. Parse DB rows and group them by normalized deadline date
    //   for (var row in dbRows) {
    //     AppTask task = AppTask.fromMap(row);
    //     DateTime key = _normalizeDate(task.deadline);

    //     if (loadedEvents[key] == null) {
    //       loadedEvents[key] = [];
    //     }
    //     loadedEvents[key]!.add(task);
    //   }

    //   setState(() {
    //     _events = loadedEvents;
    //     _isLoading = false;
    //   });
    // } catch (e) {
    //   // Fallback/Safety state if local database returns an exception or is initializing
    //   setState(() => _isLoading = false);
    // }
  }

  /// Event loader function passed directly to TableCalendar grid
  List<AppTask> _getTasksForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = _selectedDay != null ? _getTasksForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar & Deadlines'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTasksFromLocalDb,
            tooltip: 'Refresh DB Tasks',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Table Calendar Grid Widget
                TableCalendar<AppTask>(
                  firstDay: DateTime.utc(2025, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getTasksForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blueAccent.shade200,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                ),

                const SizedBox(height: 8),
                const Divider(thickness: 1),

                // 2. Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _selectedDay == null
                          ? 'Select a date'
                          : 'Tasks for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}:',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // 3. Task List View for Selected Date
                Expanded(
                  child: selectedTasks.isEmpty
                      ? const Center(
                          child: Text(
                            'No tasks or deadlines for this day.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: selectedTasks.length,
                          itemBuilder: (context, index) {
                            final task = selectedTasks[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: task.difficulty == 'Hard'
                                      ? Colors.red.shade100
                                      : task.difficulty == 'Medium'
                                          ? Colors.orange.shade100
                                          : Colors.green.shade100,
                                  child: Icon(
                                    task.isRecurring ? Icons.autorenew : Icons.assignment,
                                    color: task.difficulty == 'Hard'
                                        ? Colors.red
                                        : task.difficulty == 'Medium'
                                            ? Colors.orange
                                            : Colors.green,
                                  ),
                                ),
                                title: Text(
                                  task.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Difficulty: ${task.difficulty} | Subtasks: ${task.subtaskCount}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  _showTaskDetailBottomSheet(context, task);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  /// Full Task Details Bottom Sheet View
  void _showTaskDetailBottomSheet(BuildContext context, AppTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    label: Text(
                      task.difficulty,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: task.difficulty == 'Hard'
                        ? Colors.red
                        : task.difficulty == 'Medium'
                            ? Colors.orange
                            : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Deadline: ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Subtasks Count: ${task.subtaskCount}',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Recurring Task: ', style: TextStyle(fontSize: 15)),
                  Icon(
                    task.isRecurring ? Icons.check_circle : Icons.cancel,
                    color: task.isRecurring ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
