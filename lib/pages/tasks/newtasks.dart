import 'dart:async';
import 'package:flutter/material.dart';
import 'package:actiphibian/models/habit.dart';
import 'package:actiphibian/models/focus_session.dart';
import 'package:actiphibian/models/task.dart';
import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/data/userManager.dart';
import 'package:provider/provider.dart';
import 'package:actiphibian/utils/task_parsers.dart';
import 'package:actiphibian/utils/task_creation_logger.dart';
import 'package:actiphibian/services/recurrence.dart';
import 'package:actiphibian/services/xp_calculator.dart';
import 'package:actiphibian/services/user_progress.dart';
import 'package:actiphibian/services/task_labels.dart';
import 'package:actiphibian/widgets/progress_header.dart';
import 'package:actiphibian/widgets/task_calendar.dart';
import 'package:actiphibian/widgets/task_card.dart';
import 'package:actiphibian/widgets/task_form_dialog.dart';
import 'package:actiphibian/widgets/user_stats_app_bar.dart';

class NewTasks extends StatefulWidget {
  const NewTasks({super.key});

  @override
  State<NewTasks> createState() => _NewTasksState();
}

class _NewTasksState extends State<NewTasks> {
  final List<Task> _tasks = [];
  final List<Habit> _habits = [];
  List<FocusSession> _focusSessions = const [];
  final List<Future<void>> _pendingHabitWrites = [];
  int _nextHabitId = 1;
  bool _isLoading = true;
  String? _habitWriteError;

  static const List<String> _defaultHabitNames = [
    'Academic',
    'Health',
    'Hygiene',
    'Music',
  ];

  Habit _createHabit(String name) {
    // The current dialog expects a synchronous callback, so assign a local ID
    // immediately and queue the matching SQLite write before saving its task.
    final habit = Habit(id: _nextHabitId++, name: name);
    if (mounted) setState(() => _habits.add(habit));

    final write = LocalDb.addHabit(habit)
        .then<void>((_) {})
        .catchError((Object error) {
          _habitWriteError = error.toString();
        });
    _pendingHabitWrites.add(write);
    return habit;
  }

  Future<void> _loadData() async {
    try {
      var habits = await LocalDb.getHabits();
      if (habits.isEmpty) {
        // Preserve the four built-in choices that the screen already showed.
        for (var i = 0; i < _defaultHabitNames.length; i++) {
          await LocalDb.addHabit(Habit(id: i + 1, name: _defaultHabitNames[i]));
        }
        habits = await LocalDb.getHabits();
      }
      final tasks = await LocalDb.getTasks();
      final focusSessions = await LocalDb.getFocusSessions();
      if (!mounted) return;

      setState(() {
        _habits
          ..clear()
          ..addAll(habits);
        _tasks
          ..clear()
          ..addAll(tasks);
        _focusSessions = focusSessions;
        _nextHabitId = habits.fold<int>(1, (nextId, habit) {
          final id = habit.id ?? 0;
          return id >= nextId ? id + 1 : nextId;
        });
        _isLoading = false;
      });
      _syncProgressToUserManager();
      _flagNewlyMissedTasks();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _reportDatabaseError('Could not load tasks and habits', error);
    }
  }

  Future<void> _waitForPendingHabitWrites() async {
    final pending = List<Future<void>>.from(_pendingHabitWrites);
    _pendingHabitWrites.clear();
    await Future.wait(pending);
    if (_habitWriteError != null) {
      final error = _habitWriteError!;
      _habitWriteError = null;
      throw StateError('Could not save the new habit: $error');
    }
  }

  void _reportDatabaseError(String message, Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$message: $error')));
  }

  void _saveTaskSilently(Task task) {
    LocalDb.updateTask(task).catchError((Object error) {
      _reportDatabaseError('Could not save task changes', error);
    });
  }

  String _habitName(int? habitId) {
    if (habitId == null) return 'None';
    for (final h in _habits) {
      if (h.id == habitId) return h.name;
    }
    return 'None';
  }

  // Coins earned are derived from total XP, so only spending needs storing.
  final int _coinsSpent = 0;

  void _syncProgressToUserManager() {
    final progress = _progress;
    context.read<UserManager>().updateProgress(
      level: progress.level,
      xp: progress.totalXp,
      balance: progress.coins,
    );
  }

  Timer? _missedCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _missedCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isLoading) _flagNewlyMissedTasks();
    });
  }

  @override
  void dispose() {
    _missedCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _showAddTaskDialog() async {
    final result = await showTaskFormDialog(
      context,
      habits: _habits,
      onCreateHabit: _createHabit,
    );
    if (result == null || !mounted) return;

    final taskDraft = Task(
      description: result.description,
      subtasks: TaskParsers.parseSubtasks(result.subtasksRaw),
      durationMinutes: result.durationMinutes,
      deadline: result.deadline,
      recurring: result.recurring,
      recurrenceFrequency: result.recurrenceFrequency,
      difficulty: result.difficulty,
      habitId: result.habitId,
    );

    late final Task newTask;
    try {
      // A task might refer to a habit created inside the same dialog. Make
      // sure that habit's insert finishes before storing the task.
      await _waitForPendingHabitWrites();
      final taskId = await LocalDb.addTask(taskDraft);
      newTask = taskDraft.copyWith(id: taskId);
    } catch (error) {
      _reportDatabaseError('Could not save the task', error);
      return;
    }
    if (!mounted) return;
    setState(() => _tasks.add(newTask));

    // Logging is a debug aid and must never block adding a task (web has no filesystem).
    try {
      await TaskCreationLogger.logTaskCreated(
        title: newTask.description,
        subtasksRaw: result.subtasksRaw,
        durationRaw: result.durationMinutes?.toString() ?? '',
        deadlineRaw: TaskLabels.deadlineLabel(result.deadline),
        isRecurring: result.recurring,
        difficulty: TaskLabels.difficultyLabel(result.difficulty),
      );
      // ignore: avoid_print
      print(await TaskCreationLogger.readLog());
    } catch (_) {}

    if (!mounted) return;
    if (newTask.habitId == null) _showNoHabitNotice(newTask);
  }

  void _showNoHabitNotice(Task task) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        showCloseIcon: true,
        content: InkWell(
          onTap: () {
            messenger.hideCurrentSnackBar();
            final index = _tasks.indexWhere((t) => t.id == task.id);
            if (index != -1 && _tasks[index].status == 'active') {
              _showEditTaskDialog(index);
            }
          },
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '${task.description} has no habit',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditTaskDialog(int index) async {
    final task = _tasks[index];
    final result = await showTaskFormDialog(
      context,
      habits: _habits,
      onCreateHabit: _createHabit,
      existing: task,
    );
    if (result == null || !mounted) return;

    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i == -1) return;

    try {
      await _waitForPendingHabitWrites();
      final updatedTask = _tasks[i].copyWith(
        // An explicit null clears a field (habit, duration, frequency).
        description: result.description,
        subtasks: TaskParsers.parseSubtasks(result.subtasksRaw),
        durationMinutes: result.durationMinutes,
        deadline: result.deadline,
        recurring: result.recurring,
        recurrenceFrequency: result.recurrenceFrequency,
        difficulty: result.difficulty,
        habitId: result.habitId,
      );
      await LocalDb.updateTask(updatedTask);
      if (!mounted) return;
      setState(() => _tasks[i] = updatedTask);
    } catch (error) {
      _reportDatabaseError('Could not update the task', error);
    }
  }

  void _toggleSubtask(int taskIndex, int subtaskIndex) {
    final task = _tasks[taskIndex];
    final updatedSubtasks = List<Subtask>.from(task.subtasks);
    updatedSubtasks[subtaskIndex] = updatedSubtasks[subtaskIndex].copyWith(
      isDone: !updatedSubtasks[subtaskIndex].isDone,
    );
    final updatedTask = task.copyWith(subtasks: updatedSubtasks);
    setState(() => _tasks[taskIndex] = updatedTask);
    _saveTaskSilently(updatedTask);
  }

  Future<void> _markTaskComplete(int index) async {
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
    // A recurring task is recorded as done and the next occurrence is created as a new task.
    Task? nextOccurrence;
    if (task.isRecurring && task.deadline != null) {
      nextOccurrence = Task(
        description: task.description,
        subtasks: task.subtasks.map((s) => s.copyWith(isDone: false)).toList(),
        durationMinutes: task.durationMinutes,
        deadline: Recurrence.nextAfterCompletion(
          deadline: task.deadline!,
          frequency: task.recurrenceFrequency!,
          completedAt: now,
        ),
        recurring: true,
        recurrenceFrequency: task.recurrenceFrequency,
        difficulty: task.difficulty,
        habitId: task.habitId,
      );
    }
    final completedTask = task.copyWith(
      status: 'completed',
      completedAt: now,
      xpAwarded: xpEarned,
    );
    try {
      final nextId = await LocalDb.saveTaskCompletion(
        completedTask,
        nextOccurrence,
      );
      if (nextOccurrence != null && nextId != null) {
        nextOccurrence = nextOccurrence.copyWith(id: nextId);
      }
    } catch (error) {
      _reportDatabaseError('Could not save task completion', error);
      return;
    }
    if (!mounted) return;
    final currentIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (currentIndex == -1) return;
    setState(() {
      _tasks[currentIndex] = completedTask;
      if (nextOccurrence != null) _tasks.add(nextOccurrence);
    });
    _syncProgressToUserManager();
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
    if (nextOccurrence != null) {
      message +=
          ' Next one: ${TaskLabels.deadlineLabel(nextOccurrence.deadline!)}.';
    }
    final newRank = UserProgress.rankReached(progressBefore, progressAfter);
    if (newRank != null) message += ' Rank up: ${newRank.name}!';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
    await _markTaskComplete(index);
  }

  UserProgress get _progress => UserProgress.fromTasks(
    _tasks,
    now: DateTime.now(),
    coinsSpent: _coinsSpent,
    focusSessions: _focusSessions,
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
                    line(
                      'Deadline',
                      task.deadline == null
                          ? 'None'
                          : TaskLabels.deadlineLabel(task.deadline!),
                    ),
                    line(
                      'Difficulty',
                      TaskLabels.difficultyLabel(task.difficulty),
                    ),
                    line(
                      'Duration',
                      task.durationMinutes != null
                          ? TaskLabels.durationLabel(task.durationMinutes)
                          : 'Not set',
                    ),
                    line('Habit', _habitName(task.habitId)),
                    line(
                      'Repeats',
                      task.isRecurring
                          ? Recurrence.label(task.recurrenceFrequency)
                          : 'No',
                    ),
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
                          // Only completed and cancelled tasks are locked; a missed task stays editable.
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
                        // Deleting a completed task would remove its XP, since XP is derived from the task list.
                        if (task.status != 'completed')
                          TextButton.icon(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _deleteTask(taskId);
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

  Future<void> _deleteTask(int taskId) async {
    try {
      await LocalDb.deleteTask(taskId);
      if (!mounted) return;
      setState(() => _tasks.removeWhere((task) => task.id == taskId));
    } catch (error) {
      _reportDatabaseError('Could not delete the task', error);
    }
  }

  Future<void> _cancelTask(int index) async {
    final task = _tasks[index];
    final updatedTask = task.copyWith(status: 'cancelled');
    try {
      await LocalDb.updateTask(updatedTask);
      if (!mounted) return;
      final currentIndex = _tasks.indexWhere((item) => item.id == task.id);
      if (currentIndex == -1) return;
      setState(() => _tasks[currentIndex] = updatedTask);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task cancelled — no XP lost')),
      );
    } catch (error) {
      _reportDatabaseError('Could not cancel the task', error);
    }
  }

  void _flagNewlyMissedTasks() {
    // The timer can fire once more after dispose().
    if (!mounted) return;

    final now = DateTime.now();
    final newlyMissed = <String>[];
    final updatedTasks = <Task>[];

    setState(() {
      for (var i = 0; i < _tasks.length; i++) {
        final task = _tasks[i];
        final isPastDue = task.deadline != null && task.deadline!.isBefore(now);
        if (task.status == 'active' && isPastDue) {
          final updatedTask = task.copyWith(status: 'missed');
          _tasks[i] = updatedTask;
          updatedTasks.add(updatedTask);
          newlyMissed.add(task.description);
        }
      }
    });

    for (final task in updatedTasks) {
      _saveTaskSilently(task);
    }
    if (newlyMissed.isEmpty || !mounted) return;
    final label = newlyMissed.length == 1
        ? '"${newlyMissed.first}" missed its deadline'
        : '${newlyMissed.length} tasks missed their deadline';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — no XP lost. Finish it anytime.')),
    );
  }

  void _openCalendar() {
   Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: const UserStatsAppBar(title: 'Calendar'),
          body: SafeArea(
            child: TaskCalendar(
              tasks: List<Task>.of(_tasks),
              habits: List<Habit>.of(_habits),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final progress = _progress;
    final today = TaskLabels.todaySummary(_tasks, now);

    // Today's Tasks are those due or completed today; everything else goes under "Other tasks".
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

    // Temporary entry point until the calendar is its own tab.
    final calendarButton = IconButton(
      icon: const Icon(Icons.calendar_month),
      tooltip: 'Calendar',
      visualDensity: VisualDensity.compact,
      onPressed: _openCalendar,
    );

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: cardFor(task),
                              ),
                            if (otherTasks.isNotEmpty) heading('Other tasks'),
                            for (final task in otherTasks)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: cardFor(task),
                              ),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
