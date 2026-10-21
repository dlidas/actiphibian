import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:actiphibian/models/habit.dart';
import 'package:actiphibian/models/task.dart';
import 'package:actiphibian/services/recurrence.dart';
import 'package:actiphibian/services/task_form_validator.dart';
import 'package:actiphibian/services/task_labels.dart';
import 'package:actiphibian/utils/task_parsers.dart';
import 'package:actiphibian/widgets/habit_colors.dart';

class TaskFormResult {
  final String description;
  final String subtasksRaw;
  final int? durationMinutes;
  final DateTime deadline;
  final bool recurring;
  final String? recurrenceFrequency;
  final String difficulty;
  final int? habitId;

  const TaskFormResult({
    required this.description,
    required this.subtasksRaw,
    required this.durationMinutes,
    required this.deadline,
    required this.recurring,
    required this.recurrenceFrequency,
    required this.difficulty,
    required this.habitId,
  });
}

const int _newHabitOption = -1;

Future<TaskFormResult?> showTaskFormDialog(
  BuildContext context, {
  required List<Habit> habits,
  required Habit Function(String name) onCreateHabit,
  Task? existing,
}) {
  return showDialog<TaskFormResult>(
    context: context,
    builder: (dialogContext) => _TaskFormDialog(
      habits: habits,
      onCreateHabit: onCreateHabit,
      existing: existing,
    ),
  );
}

class _TaskFormDialog extends StatefulWidget {
  final List<Habit> habits;
  final Habit Function(String name) onCreateHabit;
  final Task? existing;

  const _TaskFormDialog({
    required this.habits,
    required this.onCreateHabit,
    required this.existing,
  });

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  late final TextEditingController _description;
  late final TextEditingController _subtasks;
  late final TextEditingController _duration;
  late final List<Habit> _habitOptions;

  DateTime? _deadline;
  bool _recurring = false;
  String? _frequency;
  String _difficulty = 'easy';
  int? _habitId;
  bool _showErrors = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _description = TextEditingController(text: t?.description ?? '');
    _subtasks = TextEditingController(
      text: t == null ? '' : TaskParsers.formatSubtasksForEditing(t.subtasks),
    );
    _duration = TextEditingController(
      text: t?.durationMinutes?.toString() ?? '',
    );
    _habitOptions = List<Habit>.of(widget.habits);
    _deadline = t?.deadline;
    _recurring = t?.recurring ?? false;
    _frequency = t?.recurrenceFrequency;
    _difficulty = t?.difficulty ?? 'easy';
    _habitId = t?.habitId;
  }

  @override
  void dispose() {
    _description.dispose();
    _subtasks.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _deadline;
    final currentDay = current == null
        ? null
        : DateTime(current.year, current.month, current.day);
    final firstDate = (currentDay != null && currentDay.isBefore(today))
        ? currentDay
        : today;

    final date = await showDatePicker(
      context: context,
      initialDate: currentDay ?? today,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 10, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: _recurring ? 'First due date' : 'Deadline date',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: current != null
          ? TimeOfDay.fromDateTime(current)
          : const TimeOfDay(hour: 23, minute: 59),
      helpText: _recurring ? 'First due time' : 'Deadline time',
    );
    if (!mounted) return;

    setState(() {
      _deadline = time == null
          ? DateTime(date.year, date.month, date.day, 23, 59, 59)
          : DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _createHabit() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New habit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Habit name',
            hintText: 'e.g. Academic',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    final habit = widget.onCreateHabit(name);
    setState(() {
      _habitOptions.add(habit);
      _habitId = habit.id;
    });
  }

  TaskFormErrors _validate() {
    final existing = widget.existing;
    return TaskFormValidator.validate(
      description: _description.text,
      deadline: _deadline,
      recurring: _recurring,
      frequency: _frequency,
      now: DateTime.now(),
      checkPast: existing == null || existing.deadline != _deadline,
    );
  }

  void _submit() {
    if (_validate().hasErrors) {
      setState(() => _showErrors = true);
      return;
    }
    final now = DateTime.now();
    Navigator.pop(
      context,
      TaskFormResult(
        description: _description.text.trim(),
        subtasksRaw: _subtasks.text,
        durationMinutes: TaskParsers.parseDuration(_duration.text),
        // Recurring tasks with no first-due date start at the end of today.
        deadline:
            _deadline ?? DateTime(now.year, now.month, now.day, 23, 59, 59),
        recurring: _recurring,
        recurrenceFrequency: _recurring ? _frequency : null,
        difficulty: _difficulty,
        habitId: _habitId,
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 12,
    height: 12,
    margin: const EdgeInsets.only(right: 8),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    final errors = _showErrors ? _validate() : const TaskFormErrors();

    return AlertDialog(
      title: Text(_isEdit ? 'Edit Task' : 'Add New Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Description *',
                errorText: errors.description,
              ),
              onChanged: (_) {
                if (_showErrors) setState(() {});
              },
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDeadline,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _recurring ? 'First due (optional)' : 'Deadline *',
                  errorText: errors.deadline,
                  helperText: _recurring && _deadline == null
                      ? 'Starts today if left empty'
                      : null,
                  suffixIcon: (_recurring && _deadline != null)
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Clear',
                          onPressed: () => setState(() => _deadline = null),
                        )
                      : const Icon(Icons.calendar_month),
                ),
                child: Text(
                  _deadline == null
                      ? 'Tap to pick a date and time'
                      : TaskLabels.deadlineLabel(_deadline!),
                ),
              ),
            ),
            TextField(
              controller: _subtasks,
              decoration: InputDecoration(
                labelText: 'Subtasks (optional)',
                hintText: 'wash dishes, buy milk',
                // Subtasks are plain text, so editing them resets every tick.
                helperText: _isEdit
                    ? 'Editing this resets subtask check-marks'
                    : null,
              ),
            ),
            TextField(
              controller: _duration,
              decoration: const InputDecoration(
                labelText: 'Duration in minutes (optional)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Recurring'),
              value: _recurring,
              onChanged: (v) => setState(() {
                _recurring = v;
                if (v) {
                  _frequency ??= 'weekly';
                } else {
                  _frequency = null;
                }
              }),
            ),
            if (_recurring)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Repeats',
                  errorText: errors.frequency,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _frequency,
                    isExpanded: true,
                    isDense: true,
                    items: [
                      for (final f in Recurrence.frequencies)
                        DropdownMenuItem(
                          value: f,
                          child: Text(Recurrence.label(f)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _frequency = v),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Difficulty'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _difficulty,
                  isExpanded: true,
                  isDense: true,
                  items: [
                    for (final d in const ['easy', 'medium', 'hard'])
                      DropdownMenuItem(
                        value: d,
                        child: Text(TaskLabels.difficultyLabel(d)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _difficulty = v ?? 'easy'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Habit (optional)'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _habitId,
                  isExpanded: true,
                  isDense: true,
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Row(
                        children: [
                          _dot(HabitColors.none),
                          const Text('No habit'),
                        ],
                      ),
                    ),
                    for (final h in _habitOptions)
                      DropdownMenuItem<int?>(
                        value: h.id,
                        child: Row(
                          children: [
                            _dot(HabitColors.forHabit(h.id)),
                            Flexible(
                              child: Text(
                                h.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const DropdownMenuItem<int?>(
                      value: _newHabitOption,
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 14),
                          SizedBox(width: 6),
                          Text('New habit…'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == _newHabitOption) {
                      _createHabit();
                    } else {
                      setState(() => _habitId = v);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'Save changes' : 'Add'),
        ),
      ],
    );
  }
}
