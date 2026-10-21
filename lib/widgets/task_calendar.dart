import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:actiphibian/models/habit.dart';
import 'package:actiphibian/models/task.dart';
import 'package:actiphibian/services/calendar_logic.dart';
import 'package:actiphibian/widgets/habit_colors.dart';

/// Month calendar of tasks still to be done, placed on their due day (recurring tasks on every repeat).
/// Needs a bounded height.
class TaskCalendar extends StatefulWidget {
  final List<Task> tasks;

  final List<Habit> habits;

  /// Overrides today, for tests.
  final DateTime? now;

  const TaskCalendar({
    super.key,
    required this.tasks,
    this.habits = const [],
    this.now,
  });

  @override
  State<TaskCalendar> createState() => _TaskCalendarState();
}

class _TaskCalendarState extends State<TaskCalendar> {
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  late DateTime _month;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    final n = _now;
    _month = DateTime(n.year, n.month);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _showSnippet(CalendarEntry entry) {
    final snippet = CalendarLogic.snippet(entry.task, _now, due: entry.due);
    final color = HabitColors.forHabit(entry.task.habitId);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Dot(color),
                  Expanded(
                    child: Text(
                      snippet.title,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SnippetLine(icon: Icons.schedule, text: snippet.deadlineText),
              _SnippetLine(icon: Icons.checklist, text: snippet.subtaskText),
              _SnippetLine(icon: Icons.bolt, text: snippet.difficultyText),
            ],
          ),
        ),
      ),
    );
  }

  void _showDay(DateTime day, List<CalendarEntry> entries) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '${_months[day.month - 1]} ${day.day}',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in entries)
                    ListTile(
                      dense: true,
                      leading: _Dot(
                        HabitColors.forHabit(entry.task.habitId),
                        margin: false,
                      ),
                      title: Text(
                        entry.task.description.isEmpty
                            ? '(untitled task)'
                            : entry.task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showSnippet(entry);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend() {
    final shown = widget.tasks.where(CalendarLogic.isOnCalendar).toList();
    final usedIds = <int>{
      for (final t in shown)
        if (t.habitId != null) t.habitId!,
    };
    final items = <Widget>[
      for (final h in widget.habits)
        if (usedIds.contains(h.id))
          _LegendItem(HabitColors.forHabit(h.id), h.name),
      if (shown.any((t) => t.habitId == null))
        const _LegendItem(HabitColors.none, 'No habit'),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Wrap(spacing: 14, runSpacing: 4, children: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = _now;
    final today = CalendarLogic.dayOf(now);
    final days = CalendarLogic.monthGrid(_month);
    final byDay = CalendarLogic.entriesByDay(
      widget.tasks,
      rangeStart: days.first,
      rangeEnd: days.last,
      today: today,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous month',
                onPressed: () => _shiftMonth(-1),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_months[_month.month - 1]} ${_month.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _month = DateTime(now.year, now.month)),
                child: const Text('Today'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next month',
                onPressed: () => _shiftMonth(1),
              ),
            ],
          ),
        ),
        _legend(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (final w in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(w, style: const TextStyle(fontSize: 11)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(
              children: [
                for (var week = 0; week < 6; week++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var d = 0; d < 7; d++)
                          Expanded(
                            child: _buildCell(
                              days[week * 7 + d],
                              today,
                              byDay[days[week * 7 + d]] ??
                                  const <CalendarEntry>[],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCell(DateTime day, DateTime today, List<CalendarEntry> entries) {
    final cs = Theme.of(context).colorScheme;
    final inMonth = day.month == _month.month;
    final isToday = day == today;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxChips = math.max(
          0,
          math.min(3, ((constraints.maxHeight - 24) / 16).floor()),
        );
        final visible = entries.length <= maxChips
            ? entries.length
            : math.max(maxChips - 1, 0);
        final remaining = entries.length - visible;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: entries.isEmpty ? null : () => _showDay(day, entries),
            child: Container(
              margin: const EdgeInsets.all(1),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isToday ? cs.primary.withAlpha(60) : null,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isToday ? cs.onPrimary : cs.outline.withAlpha(60),
                ),
              ),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 2),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: inMonth ? null : Colors.grey,
                          ),
                        ),
                      ),
                      for (final entry in entries.take(visible))
                        _TaskChip(
                          entry: entry,
                          onTap: () => _showSnippet(entry),
                        ),
                      if (remaining > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            '+$remaining',
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TaskChip extends StatelessWidget {
  final CalendarEntry entry;
  final VoidCallback onTap;

  const _TaskChip({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final task = entry.task;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: HabitColors.forHabit(task.habitId),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Container(
            height: 14,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              task.description.isEmpty ? '(untitled)' : task.description,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final bool margin;

  const _Dot(this.color, {this.margin = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: EdgeInsets.only(right: margin ? 8 : 0),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _SnippetLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SnippetLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
