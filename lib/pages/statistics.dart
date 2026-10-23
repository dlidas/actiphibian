import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/data/userManager.dart';
import 'package:actiphibian/models/stats.dart';
import 'package:actiphibian/widgets/pond_message_state.dart';
import 'package:actiphibian/widgets/user_stats_app_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  static const _statisticOptions = [
    'Tasks Completed',
    'Tasks Incomplete',
    'Hours Focused',
    'Times Distracted',
    'Currency Earned',
    'Currency Spent',
    'XP Gained',
    'Amphibians Collected',
    'Longest Streak',
  ];

  String selectedStatistic = 'XP Gained';
  Statistics? statistics;
  bool isLoading = true;
  Object? loadError;
  int? _loadedUserId;
  bool _hasObservedUserId = false;
  // Ignore results from earlier requests if the active user changes mid-load.
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
    _loadStatistics(userId, ++_loadGeneration);
  }

  Future<void> _loadStatistics(int? userId, int generation) async {
    if (userId == null) return;
    try {
      final results = await LocalDb.getStatistics();
      final userResults = results.where((entry) => entry.user_id == userId);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        statistics = userResults.isEmpty ? null : userResults.first;
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
    _loadStatistics(_loadedUserId, generation);
  }

  double _selectedValue(Statistics stats) {
    switch (selectedStatistic) {
      case 'Tasks Completed':
        return stats.tasks_completed.toDouble();
      case 'Tasks Incomplete':
        return stats.tasks_incompleted.toDouble();
      case 'Hours Focused':
        return stats.hours_focused ?? 0.0;
      case 'Times Distracted':
        return stats.times_distracted.toDouble();
      case 'Currency Earned':
        return stats.total_currency_earned.toDouble();
      case 'Currency Spent':
        return stats.total_currency_spent.toDouble();
      case 'XP Gained':
        return stats.total_xp_gained.toDouble();
      case 'Amphibians Collected':
        return stats.total_amphibians_collected.toDouble();
      case 'Longest Streak':
        return stats.longest_streak.toDouble();
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final stats = statistics;

    return Scaffold(
      appBar: const UserStatsAppBar(title: 'Statistics'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
          ? PondMessageState(
              icon: Icons.cloud_off_outlined,
              message: 'Statistics could not be loaded.',
              action: TextButton(
                onPressed: _retryLoad,
                child: const Text('Try again'),
              ),
            )
          : stats == null
          ? const PondMessageState(
              icon: Icons.insights_outlined,
              message: 'Your statistics will appear here as you make progress.',
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // The database stores cumulative totals, not per-period values.
                Text(
                  'All-time statistics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButton<String>(
                          value: selectedStatistic,
                          isExpanded: true,
                          items: [
                            for (final option in _statisticOptions)
                              DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ),
                          ],
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() => selectedStatistic = value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 250,
                          child: BarChart(
                            BarChartData(
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: _selectedValue(stats),
                                      width: 36,
                                      color: colors.onPrimary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            selectedStatistic,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
