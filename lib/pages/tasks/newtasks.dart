import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:actiphibian/models/habit.dart';
import 'package:actiphibian/models/focus_session.dart';
import 'package:actiphibian/models/task.dart';
import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/data/user_manager.dart';
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

  String _newRecurringSeriesId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final nonce = math.Random.secure().nextInt(1 << 32).toRadixString(36);
    return 'series-$timestamp-$nonce';
  }

  Habit _createHabit(String name) {
    // The current dialog expects a synchronous callback, so assign a local ID
    // immediately and queue the matching SQLite write before saving its task.
    final habit = Habit(id: _nextHabitId++, name: name);
    if (mounted) setState(() => _habits.add(habit));

    final write = LocalDb.addHabit(habit).then<void>((_) {}).catchError((
      Object error,
    ) {
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
      final storedTasks = await LocalDb.getTasks();
      final tasks = <Task>[];
      for (final task in storedTasks) {
        // Older database versions did not store series identity. Start each
        // currently active legacy recurrence as its own series to avoid
        // accidentally merging two separate tasks with the same title.
        if (task.isRecurring &&
            task.status == 'active' &&
            task.recurringSeriesId == null) {
          final identifiedTask = task.copyWith(
            recurringSeriesId: _newRecurringSeriesId(),
          );
          await LocalDb.updateTask(identifiedTask);
          tasks.add(identifiedTask);
        } else {
          tasks.add(task);
        }
      }
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
      unawaited(_flagNewlyMissedTasks());
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

  // Logs the technical error and shows the user a plain message.
  void _reportDatabaseError(String message, Object error) {
    debugPrint('$message: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$message. Please try again.')));
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

  // Coins earned are derived from total XP, so only spendable coins needs storing and not the total cummulative coins user has earned.
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
  Set<int?> _lockedTaskIds = {};

  Set<int?> _currentLockedTaskIds(DateTime now) => {
    for (final task in _tasks)
      if (task.status == 'active' && !_isTaskInteractable(task, now)) task.id,
  };

  // Redraw when a repeating task opens, so its card drops the lock icon.
  void _refreshLockedTasks() {
    // The timer can fire once more after dispose().
    if (!mounted) return;
    final locked = _currentLockedTaskIds(DateTime.now());
    if (locked.length == _lockedTaskIds.length &&
        locked.containsAll(_lockedTaskIds)) {
      return;
    }
    setState(() => _lockedTaskIds = locked);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _missedCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isLoading) return;
      _refreshLockedTasks();
      unawaited(_flagNewlyMissedTasks());
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
      recurringSeriesId: result.recurring && result.recurrenceFrequency != null
          ? _newRecurringSeriesId()
          : null,
    );

    late final Task newTask;
    try {
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

  // Match edited subtasks to their previous versions by normalized text. This
  // keeps checkmarks for unchanged subtasks while new subtasks start unchecked.
  // Matching one old item at a time also handles duplicate subtask labels.
  List<Subtask> _preserveSubtaskProgress(
    List<Subtask> existing,
    List<Subtask> edited,
  ) {
    String key(String value) =>
        value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

    final unmatched = List<Subtask>.of(existing);
    return edited.map((candidate) {
      final normalizedText = key(candidate.text);
      final matchIndex = unmatched.indexWhere(
        (previous) => key(previous.text) == normalizedText,
      );
      if (matchIndex == -1) {
        return candidate.copyWith(isDone: false);
      }
      final previous = unmatched.removeAt(matchIndex);
      return candidate.copyWith(isDone: previous.isDone);
    }).toList();
  }

  Future<void> _showEditTaskDialog(int index) async {
    if (index < 0 || index >= _tasks.length) return;
    final task = _tasks[index];
    if (!_isTaskInteractable(task, DateTime.now())) return;
    final result = await showTaskFormDialog(
      context,
      habits: _habits,
      onCreateHabit: _createHabit,
      existing: task,
    );
    if (result == null || !mounted) return;

    var currentIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (currentIndex == -1) return;

    try {
      await _waitForPendingHabitWrites();
      currentIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (currentIndex == -1) return;
      final currentTask = _tasks[currentIndex];
      // The task could have passed its deadline while the edit dialog was open.
      if (!_isTaskInteractable(currentTask, DateTime.now())) {
        unawaited(_flagNewlyMissedTasks());
        return;
      }
      final editedSubtasks = TaskParsers.parseSubtasks(result.subtasksRaw);
      final remainsRecurring =
          result.recurring && result.recurrenceFrequency != null;
      final recurringSeriesId = remainsRecurring
          ? (currentTask.isRecurring && currentTask.recurringSeriesId != null
                ? currentTask.recurringSeriesId
                : _newRecurringSeriesId())
          : null;
      final updatedTask = currentTask.copyWith(
        // An explicit null clears a field (habit, duration, frequency).
        description: result.description,
        subtasks: _preserveSubtaskProgress(
          currentTask.subtasks,
          editedSubtasks,
        ),
        durationMinutes: result.durationMinutes,
        deadline: result.deadline,
        recurring: result.recurring,
        recurrenceFrequency: result.recurrenceFrequency,
        difficulty: result.difficulty,
        habitId: result.habitId,
        recurringSeriesId: recurringSeriesId,
      );
      await LocalDb.updateTask(updatedTask);
      if (!mounted) return;
      final savedIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (savedIndex == -1) return;
      // If it expired while the database write was in flight, restore the
      // current in-memory state and run expiry processing instead of reviving it.
      if (!_isTaskInteractable(_tasks[savedIndex], DateTime.now())) {
        await LocalDb.updateTask(_tasks[savedIndex]);
        unawaited(_flagNewlyMissedTasks());
        return;
      }
      setState(() => _tasks[savedIndex] = updatedTask);
    } catch (error) {
      _reportDatabaseError('Could not update the task', error);
    }
  }

  // A recurring task becomes available at its scheduled deadline and stays
  // available until the next recurrence starts.
  DateTime _nextRecurringDeadline(Task task, DateTime deadline) {
    final frequency = task.recurrenceFrequency;
    if (frequency == null) {
      throw StateError('Recurring task has no recurrence frequency.');
    }
    final next = Recurrence.nextAfterCompletion(
      deadline: deadline,
      frequency: frequency,
      completedAt: deadline.add(const Duration(microseconds: 1)),
    );
    if (!next.isAfter(deadline)) {
      throw StateError('Recurrence did not advance beyond its deadline.');
    }
    return next;
  }

  // If the app was closed for several recurrence periods, use the latest
  // scheduled occurrence at or before now as the new active occurrence.
  DateTime _latestRecurringDeadlineAtOrBefore(Task task, DateTime now) {
    var latest = task.deadline!;
    var next = _nextRecurringDeadline(task, latest);
    var guard = 0;
    while (!now.isBefore(next) && guard < 500) {
      latest = next;
      next = _nextRecurringDeadline(task, latest);
      guard++;
    }
    return latest;
  }

  bool _isTaskInteractable(Task task, DateTime now) {
    if (task.status != 'active') return false;
    final deadline = task.deadline;
    if (deadline == null) return true;

    if (task.isRecurring) {
      if (now.isBefore(deadline)) return false;
      // A malformed recurring task without a frequency cannot be advanced;
      // allow its first occurrence after the scheduled instant rather than
      // making it permanently inaccessible.
      if (task.recurrenceFrequency == null) return true;
      final nextDeadline = _nextRecurringDeadline(task, deadline);
      return now.isBefore(nextDeadline);
    }

    // One-off tasks become failed as soon as their deadline has passed.
    return !now.isAfter(deadline);
  }

  bool _canOpenTask(Task task, DateTime now) {
    if (task.status == 'missed') return false;
    if (task.status == 'completed' || task.status == 'cancelled') {
      return true; // Historical details remain readable.
    }
    return _isTaskInteractable(task, now);
  }

  int _recurringStreakBefore(Task task) {
    final seriesId = task.recurringSeriesId;
    if (!task.isRecurring || task.deadline == null || seriesId == null) {
      return 0;
    }

    final previousOccurrences = _tasks.where((candidate) {
      return candidate.id != task.id &&
          candidate.isRecurring &&
          candidate.recurringSeriesId == seriesId &&
          candidate.deadline != null &&
          candidate.deadline!.isBefore(task.deadline!);
    }).toList()..sort((a, b) => b.deadline!.compareTo(a.deadline!));

    // Count only the consecutive successful occurrences since the latest
    // non-completed occurrence. A missed recurring task therefore resets the
    // streak, while older completed tasks remain in the history.
    var streak = 0;
    for (final previous in previousOccurrences) {
      if (previous.status != 'completed') break;
      streak++;
    }
    return streak;
  }

  Task _newRecurringOccurrence(Task source, DateTime deadline) => Task(
    description: source.description,
    subtasks: source.subtasks.map((s) => s.copyWith(isDone: false)).toList(),
    durationMinutes: source.durationMinutes,
    deadline: deadline,
    recurring: true,
    recurrenceFrequency: source.recurrenceFrequency,
    difficulty: source.difficulty,
    habitId: source.habitId,
    recurringSeriesId: source.recurringSeriesId,
  );

  void _toggleSubtask(int taskIndex, int subtaskIndex) {
    if (taskIndex < 0 || taskIndex >= _tasks.length) return;
    final task = _tasks[taskIndex];
    if (!_isTaskInteractable(task, DateTime.now())) return;
    if (subtaskIndex < 0 || subtaskIndex >= task.subtasks.length) return;
    final updatedSubtasks = List<Subtask>.from(task.subtasks);
    updatedSubtasks[subtaskIndex] = updatedSubtasks[subtaskIndex].copyWith(
      isDone: !updatedSubtasks[subtaskIndex].isDone,
    );
    final updatedTask = task.copyWith(subtasks: updatedSubtasks);
    setState(() => _tasks[taskIndex] = updatedTask);
    _saveTaskSilently(updatedTask);
  }

  Future<void> _markTaskComplete(int index) async {
    if (index < 0 || index >= _tasks.length) return;
    final task = _tasks[index];
    final now = DateTime.now();
    if (!_isTaskInteractable(task, now)) {
      // Update an expired occurrence to failed, and generate the next one if
      // necessary. A missed task must never be awarded XP.
      unawaited(_flagNewlyMissedTasks());
      return;
    }

    final progressBefore = _progress;
    final isLate =
        !task.isRecurring &&
        task.deadline != null &&
        now.isAfter(task.deadline!);
    final completionsToday = XpCalculator.completionsOnDay(
      _tasks
          .where(
            (t) =>
                !t.isRecurring &&
                t.status == 'completed' &&
                t.completedAt != null,
          )
          .map((t) => t.completedAt!),
      now,
    );
    final recurringCompletionCount = task.isRecurring
        ? _recurringStreakBefore(task) + 1
        : 0;
    final milestoneBonus = task.isRecurring
        ? XpCalculator.recurringMilestoneBonus(
            difficulty: task.difficulty,
            completionCount: recurringCompletionCount,
          )
        : 0;
    final xpEarned = XpCalculator.xpForCompletion(
      difficulty: task.difficulty,
      createdAt: task.createdAt,
      deadline: task.deadline,
      completedAt: now,
      completionsToday: completionsToday,
      isRecurring: task.isRecurring,
      recurringCompletionCount: recurringCompletionCount,
    );

    // A successfully completed recurring occurrence creates its next scheduled
    // occurrence. Subtask checkmarks are reset only on that new occurrence.
    Task? nextOccurrence;
    if (task.isRecurring &&
        task.deadline != null &&
        task.recurrenceFrequency != null) {
      nextOccurrence = _newRecurringOccurrence(
        task,
        Recurrence.nextAfterCompletion(
          deadline: task.deadline!,
          frequency: task.recurrenceFrequency!,
          completedAt: now,
        ),
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
        ? 'Task completed — +$xpEarned XP$coinsText.'
        : 'Task completed! +$xpEarned XP$coinsText';
    if (task.isRecurring && milestoneBonus > 0) {
      message +=
          ' $recurringCompletionCount-completion milestone: +$milestoneBonus bonus XP!';
    }
    if (!task.isRecurring &&
        XpCalculator.dailyMultiplier(completionsToday) < 1.0) {
      message += ' Reduced XP: that was task ${completionsToday + 1} today.';
    }
    if (nextOccurrence != null) {
      message +=
          ' Next one: ${TaskLabels.deadlineLabel(nextOccurrence.deadline!)}.';
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
    var task = _tasks[index];
    if (!_isTaskInteractable(task, DateTime.now())) {
      unawaited(_flagNewlyMissedTasks());
      return;
    }

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
      task = _tasks[index];
      if (!_isTaskInteractable(task, DateTime.now())) {
        unawaited(_flagNewlyMissedTasks());
        return;
      }
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
    final initialIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (initialIndex == -1) return;
    final initialTask = _tasks[initialIndex];
    if (!_canOpenTask(initialTask, DateTime.now())) {
      unawaited(_flagNewlyMissedTasks());
      return;
    }

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
            final now = DateTime.now();
            final isOpen = _isTaskInteractable(task, now);

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
                          // Missed tasks and not-yet-due recurring tasks are locked.
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
                            label: const Text('Complete'),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _requestComplete(taskId);
                            },
                          ),
                        if (isOpen)
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
                        if ((task.status == 'active' && isOpen) ||
                            task.status == 'cancelled')
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
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return;
    final task = _tasks[index];
    if (task.status != 'cancelled' &&
        !_isTaskInteractable(task, DateTime.now())) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this task?'),
        content: Text(
          '"${task.description.isEmpty ? '(untitled task)' : task.description}" '
          'will be removed. You cannot undo this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await LocalDb.deleteTask(taskId);
      if (!mounted) return;
      setState(() => _tasks.removeWhere((task) => task.id == taskId));
    } catch (error) {
      _reportDatabaseError('Could not delete the task', error);
    }
  }

  Future<void> _cancelTask(int index) async {
    if (index < 0 || index >= _tasks.length) return;
    final task = _tasks[index];
    if (!_isTaskInteractable(task, DateTime.now())) return;
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

  Future<void> _flagNewlyMissedTasks() async {
    // The timer can fire once more after dispose().
    if (!mounted) return;

    final now = DateTime.now();
    final newlyMissed = <Task>[];
    final replacements = <Task>[];

    // Replacing a failed recurring occurrence must not make
    // the newly inserted occurrence eligible for processing in this same pass.
    for (final task in List<Task>.of(_tasks)) {
      if (task.status != 'active' || task.deadline == null) continue;

      var shouldMiss = false;
      if (task.isRecurring) {
        if (task.recurrenceFrequency == null) continue;
        final followingDeadline = _nextRecurringDeadline(task, task.deadline!);
        // A recurring occurrence is usable from its own deadline until the
        // next scheduled occurrence begins. At that instant the old one fails.
        if (!now.isBefore(followingDeadline)) {
          shouldMiss = true;
          final currentScheduledDeadline = _latestRecurringDeadlineAtOrBefore(
            task,
            now,
          );
          replacements.add(
            _newRecurringOccurrence(task, currentScheduledDeadline),
          );
        }
      } else if (now.isAfter(task.deadline!)) {
        shouldMiss = true;
      }

      if (shouldMiss) newlyMissed.add(task.copyWith(status: 'missed'));
    }

    if (newlyMissed.isEmpty || !mounted) return;

    // Mark them failed in memory before any async writes so a second timer tick
    // cannot create duplicate replacement occurrences.
    setState(() {
      for (final missedTask in newlyMissed) {
        final index = _tasks.indexWhere((task) => task.id == missedTask.id);
        if (index != -1 && _tasks[index].status == 'active') {
          _tasks[index] = missedTask;
        }
      }
    });

    for (final missedTask in newlyMissed) {
      try {
        await LocalDb.updateTask(missedTask);
      } catch (error) {
        _reportDatabaseError('Could not save missed task', error);
      }
    }

    for (final replacement in replacements) {
      try {
        final id = await LocalDb.addTask(replacement);
        if (!mounted) return;
        setState(() => _tasks.add(replacement.copyWith(id: id)));
      } catch (error) {
        _reportDatabaseError('Could not create the next recurring task', error);
      }
    }

    if (!mounted) return;
    final label = newlyMissed.length == 1
        ? '"${newlyMissed.first.description}" was marked as failed'
        : '${newlyMissed.length} tasks were marked as failed';
    final recurringReplacementCount = replacements.length;
    final replacementMessage = recurringReplacementCount > 0
        ? ' $recurringReplacementCount new recurring '
              '${recurringReplacementCount == 1 ? 'occurrence is' : 'occurrences are'} available.'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label. No XP awarded.$replacementMessage')),
    );
  }

  // Tells the user why a task card did not open, instead of doing nothing.
  void _explainLockedTask(Task task) {
    final now = DateTime.now();
    final deadline = task.deadline;
    String? message;
    if (task.status == 'missed') {
      message = 'This task was missed, so it can no longer be changed.';
    } else if (task.isRecurring && deadline != null && now.isBefore(deadline)) {
      message =
          'This repeating task opens on ${TaskLabels.deadlineLabel(deadline)}.';
    }
    // An expired one-off task is marked as failed, which shows its own message.
    unawaited(_flagNewlyMissedTasks());
    if (message == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
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
    _lockedTaskIds = _currentLockedTaskIds(now);
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
      isLocked: task.status == 'active' && !_isTaskInteractable(task, now),
      onToggleComplete: () {
        if (_isTaskInteractable(task, DateTime.now())) {
          _requestComplete(task.id!);
        } else {
          _explainLockedTask(task);
        }
      },
      onOpen: () {
        if (_canOpenTask(task, DateTime.now())) {
          _openTaskDetails(task.id!);
        } else {
          _explainLockedTask(task);
        }
      },
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
        tooltip: 'Add task',
        onPressed: _isLoading ? null : _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
