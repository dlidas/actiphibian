import 'package:flutter/material.dart';
import 'package:actiphibian/services/user_progress.dart';

class ProgressHeader extends StatelessWidget {
  final UserProgress progress;
  final String? userName;

  final VoidCallback? onCoinsTap;

  const ProgressHeader({
    super.key,
    required this.progress,
    this.userName,
    this.onCoinsTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = userName?.trim() ?? '';
    final greeting = name.isEmpty ? 'Hop to it!' : 'Hop to it, $name!';
    final next = progress.nextRank;

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primary,
                child: const Text('🐸', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Level ${progress.level} · ${progress.rank.name}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  next == null
                      ? 'Top rank: ${progress.rank.name}'
                      : 'Next rank: ${next.name}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Text(
                progress.progressLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.progressToNextRank,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
            color: cs.onPrimary,
            backgroundColor: cs.secondary,
          ),
        ],
      ),
    );
  }
}
