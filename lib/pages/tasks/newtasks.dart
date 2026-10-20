import 'dart:async';
import 'package:flutter/material.dart';
import 'package:actiphibian/models/task.dart';
import 'package:actiphibian/utils/task_parsers.dart';
import 'package:actiphibian/utils/task_creation_logger.dart';
import 'package:actiphibian/services/xp_calculator.dart';
import 'package:actiphibian/services/user_progress.dart';
import 'package:actiphibian/services/task_labels.dart';
import 'package:actiphibian/widgets/progress_header.dart';
import 'package:actiphibian/widgets/task_calendar.dart';
import 'package:actiphibian/widgets/task_card.dart';

class NewTasks extends StatefulWidget {
  const NewTasks({super.key});

  @override
  State<NewTasks> createState() => _NewTasksState();
}

class _NewTasksState extends State<NewTasks> {
  final List<Task> _tasks = [];
  int _nextId = 1;
  final int _coinsSpent = 0;

  Timer? _missedCheckTimer;

  @override
  void initState() {
    super.initState();
    // Catches anything already overdue the moment this screen opens
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _flagNewlyMissedTasks(),
    );
    _missedCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _flagNewlyMissedTasks(),
    );
  }

  @override
  void dispose() {
    _missedCheckTimer?.cancel();
    super.dispose();
  }

  String _toStorageDifficulty(String display) => display.toLowerCase();
  String _toDisplayDifficulty(String stored) {
    switch (stored) {
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      default:
        return 'Easy';
    }
  }

  //using dialog methods for CRUD functionality

  // for creating a task
  void _showAddTaskDialog() {
    final descriptionController = TextEditingController();
    final subtaskController = TextEditingController();
    final durationController = TextEditingController();
    final deadlineController = TextEditingController();
    bool recurring = false;
    String difficulty = "Easy";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Add New Task"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: "Description"),
                    ),
                    TextField(
                      controller: subtaskController,
                      decoration: InputDecoration(
                        labelText: "Subtasks",
                        hintText: "wash dishes, buy milk",
                      ),
                    ),
                    TextField(
                      controller: durationController,
                      decoration: InputDecoration(labelText: "Duration"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: deadlineController,
                      decoration: InputDecoration(
                        labelText: "Deadline (YYYY-MM-DD)",
                      ),
                    ),
                    SwitchListTile(
                      title: Text("Recurring"),
                      value: recurring,
                      onChanged: (val) {
                        setDialogState(() {
                          recurring = val;
                        });
                      },
                    ),
                    DropdownButton<String>(
                      value: difficulty,
                      items: ["Easy", "Medium", "Hard"]
                          .map(
                            (level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => difficulty = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newTask = Task(
                      id: _nextId++,
                      description: descriptionController.text,
                      subtasks: TaskParsers.parseSubtasks(
                        subtaskController.text,
                      ),
                      durationMinutes: TaskParsers.parseDuration(
                        durationController.text,
                      ),
                      deadline: TaskParsers.parseDeadline(
                        deadlineController.text,
                      ),
                      recurring: recurring,
                      difficulty: _toStorageDifficulty(difficulty),
                    );

                    setState(() {
                      //Create
                      _tasks.add(newTask);
                    });

                    // Textfile check — Just a logger that I used to check if in fact that the task is indead created
                    await TaskCreationLogger.logTaskCreated(
                      title: newTask.description,
                      subtasksRaw: subtaskController.text,
                      durationRaw: durationController.text,
                      deadlineRaw: deadlineController.text,
                      isRecurring: recurring,
                      difficulty: difficulty,
                    );
                    // ignore: avoid_print
                    print(await TaskCreationLogger.readLog());

                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //for updating/editing a task
  void _showEditTaskDialog(int index) {
    final task = _tasks[index];
    final descriptionController = TextEditingController(text: task.description);
    final subtaskController = TextEditingController(
      text: TaskParsers.formatSubtasksForEditing(task.subtasks),
    );
    final durationController = TextEditingController(
      text: task.durationMinutes?.toString() ?? '',
    );
    final deadlineController = TextEditingController(
      text: TaskParsers.formatDeadline(task.deadline) == 'No deadline'
          ? ''
          : TaskParsers.formatDeadline(task.deadline),
    );
    bool recurring = task.recurring;
    String difficulty = _toDisplayDifficulty(task.difficulty);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Edit Task"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: "Description"),
                    ),
                    TextField(
                      controller: subtaskController,
                      decoration: InputDecoration(
                        labelText: "Subtasks",

                        helperText: "Editing this resets subtask check-marks",
                      ),
                    ),
                    TextField(
                      controller: durationController,
                      decoration: InputDecoration(
                        labelText: "Duration (hours)",
                      ),
                    ),
                    TextField(
                      controller: deadlineController,
                      decoration: InputDecoration(
                        labelText: "Deadline (YYYY-MM-DD)",
                      ),
                    ),
                    SwitchListTile(
                      title: Text("Recurring"),
                      value: recurring,
                      onChanged: (val) => setDialogState(() => recurring = val),
                    ),
                    DropdownButton<String>(
                      value: difficulty,
                      items: ["Easy", "Medium", "Hard"]
                          .map(
                            (level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => difficulty = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _tasks[index] = task.copyWith(
                        description: descriptionController.text,
                        subtasks: TaskParsers.parseSubtasks(
                          subtaskController.text,
                        ),
                        durationMinutes: TaskParsers.parseDuration(
                          durationController.text,
                        ),
                        deadline: TaskParsers.parseDeadline(
                          deadlineController.text,
                        ),
                        recurring: recurring,
                        difficulty: _toStorageDifficulty(difficulty),
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Save changes"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleSubtask(int taskIndex, int subtaskIndex) {
    setState(() {
      final task = _tasks[taskIndex];
      final updatedSubtasks = List<Subtask>.from(task.subtasks);
      updatedSubtasks[subtaskIndex] = updatedSubtasks[subtaskIndex].copyWith(
        isDone: !updatedSubtasks[subtaskIndex].isDone,
      );
      _tasks[taskIndex] = task.copyWith(subtasks: updatedSubtasks);
    });
  }

  void _markTaskComplete(int index) {
    final task = _tasks[index];
    final now = DateTime.now();

    final progressBefore = _progress;
    final isLate =
        task.status == 'missed' ||
        (task.deadline != null && now.isAfter(task.deadline!));
    final completionsToday = XpCalculator.completionsOnDay(
      _tasks
          .where((t) => t.status == 'completed' && t.completedAt != null)
          .map((t) => t.completedAt!),
      now,
    );
    final xpEarned = XpCalculator.xpForCompletion(
      difficulty: task.difficulty,
      createdAt: task.createdAt,
      deadline: task.deadline,
      completedAt: now,
      completionsToday: completionsToday,
    );
    setState(() {
      _tasks[index] = task.copyWith(
        status: 'completed',
        completedAt: now,
        xpAwarded: xpEarned,
      );
    });
    final progressAfter = _progress;
    final coinsGained = progressAfter.coins - progressBefore.coins;
    final coinsText = coinsGained > 0
        ? ' (+$coinsGained ${coinsGained == 1 ? 'coin' : 'coins'})'
        : '';
    var message = isLate
        ? 'Task completed — +$xpEarned XP$coinsText. Past the deadline, so no '
              'early bonus, but nothing was taken away either.'
        : 'Task completed! +$xpEarned XP$coinsText';
    if (XpCalculator.dailyMultiplier(completionsToday) < 1.0) {
      message += ' Reduced XP: that was task ${completionsToday + 1} today.';
    }
    final newRank = UserProgress.rankReached(progressBefore, progressAfter);
    if (newRank != null) message += ' Rank up: ${newRank.name}!';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestComplete(int taskId) async {
    var index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final task = _tasks[index];
    if (task.status != 'active' && task.status != 'missed') return;

    final unchecked = task.subtasksTotalCount - task.subtasksCompletedCount;
    if (unchecked > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Complete anyway?'),
          content: Text(
            '$unchecked of ${task.subtasksTotalCount} subtasks are still unchecked.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not yet'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Complete'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      index = _tasks.indexWhere((t) => t.id == taskId);
      if (index == -1) return;
    }
    _markTaskComplete(index);
  }

  UserProgress get _progress => UserProgress.fromTasks(
    _tasks,
    now: DateTime.now(),
    coinsSpent: _coinsSpent,
  );

  void _openTaskDetails(int taskId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final index = _tasks.indexWhere((t) => t.id == taskId);
            if (index == -1) return const SizedBox.shrink();
            final task = _tasks[index];
            final isOpen = task.status == 'active' || task.status == 'missed';
            final now = DateTime.now();

            Widget line(String label, String value) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(child: Text(value)),
                ],
              ),
            );

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  20 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.description.isEmpty
                          ? '(untitled task)'
                          : task.description,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.status == 'completed'
                          ? '${TaskLabels.subtitle(task, now)} · ${TaskLabels.xpChip(task)}'
                          : TaskLabels.subtitle(task, now),
                    ),
                    const SizedBox(height: 12),
                    line('Deadline', TaskParsers.formatDeadline(task.deadline)),
                    line('Difficulty', _toDisplayDifficulty(task.difficulty)),
                    line(
                      'Duration',
                      task.durationMinutes != null
                          ? TaskLabels.durationLabel(task.durationMinutes)
                          : 'Not set',
                    ),
                    line('Recurring', task.recurring ? 'Yes' : 'No'),
                    const Divider(height: 24),
                    Text(
                      task.hasSubtasks
                          ? 'Subtasks · ${TaskLabels.subtaskLabel(task)}'
                          : 'Subtasks',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (task.hasSubtasks)
                      ...task.subtasks.asMap().entries.map((entry) {
                        final subtaskIndex = entry.key;
                        final subtask = entry.value;
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            subtask.text,
                            style: subtask.isDone
                                ? const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                  )
                                : null,
                          ),
                          value: subtask.isDone,

                          onChanged: isOpen
                              ? (_) {
                                  _toggleSubtask(index, subtaskIndex);
                                  setSheetState(() {});
                                }
                              : null,
                        );
                      })
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('None'),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isOpen)
                          FilledButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              task.status == 'missed'
                                  ? 'Complete (late)'
                                  : 'Complete',
                            ),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _requestComplete(taskId);
                            },
                          ),
                        if (task.status == 'active')
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              final i = _tasks.indexWhere(
                                (t) => t.id == taskId,
                              );
                              if (i != -1) _showEditTaskDialog(i);
                            },
                          ),
                        if (isOpen)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.block),
                            label: const Text('Cancel task'),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              final i = _tasks.indexWhere(
                                (t) => t.id == taskId,
                              );
                              if (i != -1) _cancelTask(i);
                            },
                          ),
                        if (task.status != 'completed')
                          TextButton.icon(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              setState(
                                () => _tasks.removeWhere((t) => t.id == taskId),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _cancelTask(int index) {
    setState(() {
      _tasks[index] = _tasks[index].copyWith(status: 'cancelled');
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task cancelled')));
  }

  void _flagNewlyMissedTasks() {
    if (!mounted) return;

    final now = DateTime.now();
    final newlyMissed = <String>[];

    setState(() {
      for (var i = 0; i < _tasks.length; i++) {
        final task = _tasks[i];
        final isPastDue = task.deadline != null && task.deadline!.isBefore(now);
        if (task.status == 'active' && isPastDue) {
          _tasks[i] = task.copyWith(status: 'missed');
          newlyMissed.add(task.description);
        }
      }
    });

    if (newlyMissed.isEmpty || !mounted) return;
    final label = newlyMissed.length == 1
        ? '"${newlyMissed.first}" missed its deadline'
        : '${newlyMissed.length} tasks missed their deadline';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — no XP lost. Finish it anytime.')),
    );
  }

  // Opens the month calendar with a snapshot of the current tasks.
  void _openCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Calendar')),
          body: SafeArea(child: TaskCalendar(tasks: List<Task>.of(_tasks))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final progress = _progress;
    final today = TaskLabels.todaySummary(_tasks, now);

    final todaysTasks = _tasks
        .where((t) => TaskLabels.isTodaysTask(t, now))
        .toList();
    final otherTasks = _tasks
        .where((t) => !TaskLabels.isTodaysTask(t, now))
        .toList();

    Widget cardFor(Task task) => TaskCard(
      task: task,
      now: now,
      onToggleComplete: () => _requestComplete(task.id!),
      onOpen: () => _openTaskDetails(task.id!),
    );

    Widget heading(String text, {String? trailing, Widget? action}) => Padding(
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (trailing != null)
            Text(trailing, style: const TextStyle(fontSize: 12)),
          ?action,
        ],
      ),
    );

    final calendarButton = IconButton(
      icon: const Icon(Icons.calendar_month),
      tooltip: 'Calendar',
      visualDensity: VisualDensity.compact,
      onPressed: _openCalendar,
    );

    return Scaffold(
      body: Column(
        children: [
          ProgressHeader(progress: progress),
          Expanded(
            child: _tasks.isEmpty
                ? Column(
                    children: [
                      heading(
                        "Today's Tasks",
                        trailing: today.label,
                        action: calendarButton,
                      ),
                      const Expanded(
                        child: Center(
                          child: Text('No tasks yet — tap + to add one'),
                        ),
                      ),
                    ],
                  )
                // Bottom padding keeps the last card clear of the + button.
                : ListView(
                    padding: const EdgeInsets.only(bottom: 90),
                    children: [
                      heading(
                        "Today's Tasks",
                        trailing: today.label,
                        action: calendarButton,
                      ),
                      if (todaysTasks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
                          child: Text('Nothing due today.'),
                        ),
                      for (final task in todaysTasks)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: cardFor(task),
                        ),
                      if (otherTasks.isNotEmpty) heading('Other tasks'),
                      for (final task in otherTasks)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: cardFor(task),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
