import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/data/userManager.dart';
import 'package:actiphibian/models/stats.dart';
import 'package:actiphibian/widgets/user_stats_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  Statistics? statistics;
  bool isLoading = true;
  Object? loadError;
  int? _loadedUserId;
  bool _hasObservedUserId = false;
  int _loadGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = Provider.of<UserManager>(context).user.id;
    if (_hasObservedUserId && userId == _loadedUserId) return;

    _hasObservedUserId = true;
    _loadedUserId = userId;
    statistics = null;
    loadError = null;
    isLoading = userId != null;
    _loadStatisticData(userId, ++_loadGeneration);
  }

  Future<void> _loadStatisticData(int? userId, int generation) async {
    if (userId == null) return;
    try {
      final result = await LocalDb.getStatistics();
      final userStatistics = result
          .where((entry) => entry.user_id == userId)
          .toList();

      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        statistics = userStatistics.isEmpty ? null : userStatistics.first;
        isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Could not load statistics: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        loadError = error;
        isLoading = false;
      });
    }
  }

  void _retryLoad() {
    final generation = ++_loadGeneration;
    setState(() {
      isLoading = _loadedUserId != null;
      loadError = null;
    });
    _loadStatisticData(_loadedUserId, generation);
  }

  @override
  Widget build(BuildContext context) {
    final stats = statistics;

    return Scaffold(
      appBar: const UserStatsAppBar(title: 'Statistics'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
          ? _StatisticsMessage(
              icon: Icons.cloud_off_outlined,
              message: 'Statistics could not be loaded.',
              action: TextButton(
                onPressed: _retryLoad,
                child: const Text('Try again'),
              ),
            )
          : stats == null
          ? const _StatisticsMessage(
              icon: Icons.insights_outlined,
              message: 'Your statistics will appear here as you make progress.',
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Your pond at a glance',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All-time progress and milestones',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 600 ? 3 : 2;
                    final spacing = 12.0;
                    final tileWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
                    final tiles = <_StatisticData>[
                      _StatisticData(
                        'Tasks completed',
                        '${stats.tasks_completed}',
                        Icons.task_alt,
                      ),
                      _StatisticData(
                        'Tasks incomplete',
                        '${stats.tasks_incompleted}',
                        Icons.pending_actions,
                      ),
                      _StatisticData(
                        'Hours focused',
                        (stats.hours_focused ?? 0).toStringAsFixed(1),
                        Icons.timer_outlined,
                      ),
                      _StatisticData(
                        'Times distracted',
                        '${stats.times_distracted}',
                        Icons.notifications_active_outlined,
                      ),
                      _StatisticData(
                        'Coins earned',
                        '${stats.total_currency_earned}',
                        Icons.monetization_on_outlined,
                      ),
                      _StatisticData(
                        'Coins spent',
                        '${stats.total_currency_spent}',
                        Icons.shopping_bag_outlined,
                      ),
                      _StatisticData(
                        'XP earned',
                        '${stats.total_xp_gained}',
                        Icons.bolt_outlined,
                      ),
                      _StatisticData(
                        'Amphibians collected',
                        '${stats.total_amphibians_collected}',
                        Icons.pets_outlined,
                      ),
                      _StatisticData(
                        'Longest streak',
                        '${stats.longest_streak}',
                        Icons.local_fire_department_outlined,
                      ),
                    ];

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final tile in tiles)
                          SizedBox(
                            width: tileWidth,
                            child: _StatisticTile(data: tile),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _StatisticsMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _StatisticsMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.primary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}

class _StatisticData {
  final String label;
  final String value;
  final IconData icon;

  const _StatisticData(this.label, this.value, this.icon);
}

class _StatisticTile extends StatelessWidget {
  final _StatisticData data;

  const _StatisticTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, color: colors.onPrimary),
            const SizedBox(height: 16),
            Text(
              data.value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(data.label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
