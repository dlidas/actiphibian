import 'package:flutter/material.dart';
import 'package:actiphibian/models/task.dart';
import 'package:actiphibian/services/task_labels.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final DateTime now;
  final VoidCallback onToggleComplete;
  final VoidCallback onOpen;
  // True when an active task cannot be changed yet, such as a repeating task
  // before its first due time.
  final bool isLocked;

  const TaskCard({
    super.key,
    required this.task,
    required this.now,
    required this.onToggleComplete,
    required this.onOpen,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stage = TaskLabels.stageOf(task);
    final background = _backgroundFor(stage, cs);
    // Missed tasks cannot be completed, so they get no complete button.
    final canComplete =
        !isLocked &&
        (stage == TaskStage.inProgress || stage == TaskStage.notStarted);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
            decoration: stage == TaskStage.notStarted
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.primary.withAlpha(70)),
                  )
                : null,
            child: Row(
              children: [
                _StatusCircle(
                  task: task,
                  stage: stage,
                  onTap: canComplete ? onToggleComplete : null,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.description.isEmpty
                            ? '(untitled task)'
                            : task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration: stage == TaskStage.cancelled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (stage == TaskStage.inProgress) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: task.subtaskProgress,
                            minHeight: 5,
                            color: cs.tertiary,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        TaskLabels.subtitle(task, now),
                        style: TextStyle(color: cs.secondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (stage == TaskStage.done)
                  _XpChip(text: TaskLabels.xpChip(task))
                else if (isLocked || stage == TaskStage.missed)
                  Icon(Icons.lock_outline, color: cs.secondary, size: 20)
                else
                  Icon(Icons.chevron_right, color: cs.secondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundFor(TaskStage stage, ColorScheme cs) {
    switch (stage) {
      case TaskStage.done:
        return cs.onPrimary;
      case TaskStage.inProgress:
        return Color.alphaBlend(cs.tertiary.withAlpha(70), cs.onPrimary);
      case TaskStage.notStarted:
        return Color.alphaBlend(const Color(0x40000000), cs.onPrimary);
      case TaskStage.missed:
        return const Color(0xFF37474F);
      case TaskStage.cancelled:
        return const Color(0xFF424242);
    }
  }
}

class _StatusCircle extends StatelessWidget {
  final Task task;
  final TaskStage stage;
  final VoidCallback? onTap;

  const _StatusCircle({
    required this.task,
    required this.stage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget circle;
    switch (stage) {
      case TaskStage.done:
        circle = CircleAvatar(
          radius: 18,
          backgroundColor: cs.primary.withAlpha(110),
          child: const Icon(Icons.check, color: Colors.white, size: 20),
        );
        break;
      case TaskStage.inProgress:
        circle = SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            value: task.subtaskProgress,
            strokeWidth: 4,
            color: cs.tertiary,
            backgroundColor: Colors.white24,
          ),
        );
        break;
      case TaskStage.notStarted:
        circle = Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 2),
          ),
        );
        break;
      case TaskStage.missed:
        circle = const Icon(Icons.event_busy, color: Colors.white70, size: 30);
        break;
      case TaskStage.cancelled:
        circle = const Icon(Icons.cancel, color: Colors.white54, size: 30);
        break;
    }
    final target = SizedBox(
      width: 48,
      height: 48,
      child: Center(child: circle),
    );
    if (onTap == null) return target;
    return Tooltip(
      message: 'Mark complete',
      child: InkResponse(onTap: onTap, radius: 26, child: target),
    );
  }
}

class _XpChip extends StatelessWidget {
  final String text;
  const _XpChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Color.alphaBlend(cs.tertiary.withAlpha(90), cs.onPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.tertiary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
