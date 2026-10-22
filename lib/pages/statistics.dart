import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/data/userManager.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:actiphibian/models/stats.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String selectedStatistic = "XP Earned";

  Statistics? statistics;
  bool isLoading = true;

  Future<void> loadStatisticData() async {
    final int? userId = context.read<UserManager>().user.id;

    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    final result = await LocalDb.getStatistics();
    print("Printing tasks completed when selected");

    if (!mounted) return;

    setState(() {
      statistics = result.first;
      isLoading = false;
      print(statistics);
    });
  }

  List<double> getSelectedData() {
  if (statistics == null) return [];

  switch (selectedStatistic) {
    case "Tasks Completed":
      return [statistics!.tasks_completed.toDouble()];

    case "Tasks Incomplete":
      return [statistics!.tasks_incompleted.toDouble()];

    case "Hours Focused":
      return [statistics?.hours_focused?.toDouble() ?? 0.0];

    case "Times Distracted":
      return [statistics!.times_distracted.toDouble()];

    case "Currency Earned":
      return [statistics!.total_currency_earned.toDouble()];

    case "Currency Spent":
      return [statistics!.total_currency_spent.toDouble()];

    case "XP Gained":
      return [statistics!.total_xp_gained.toDouble()];

    case "Amphibians Collected":
      return [statistics!.total_amphibians_collected.toDouble()];

    case "Longest Streak":
      return [statistics!.longest_streak.toDouble()];

    default:
      return [];
  }
}

  @override
  Widget build(BuildContext context) {
    final List<double> chartData = getSelectedData();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Statistics"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Daily Statistics
              const Text(
                "Daily Statistics",
                style: TextStyle(fontSize: 24),
              ),

              const SizedBox(height: 20),

              DropdownButton<String> (
                value: selectedStatistic,

                isExpanded: true,

                items: const [
                  DropdownMenuItem(
                    value: "Tasks Completed",
                    child: Text("Tasks Completed"),
                  ),
                  DropdownMenuItem(
                    value: "Tasks Incompleted",
                    child: Text("Tasks Incomplete"),
                  ),
                  DropdownMenuItem(
                    value: "Hours Focused",
                    child: Text("Hours Focused"),
                  ),
                  DropdownMenuItem(
                    value: "Times Distracted",
                    child: Text("Times Distracted"),
                  ),
                  DropdownMenuItem(
                    value: "Currency Earned",
                    child: Text("Currency Earned"),
                  ),
                  DropdownMenuItem(
                    value: "Currency Spent",
                    child: Text("Currency Spent"),
                  ),
                  DropdownMenuItem(
                    value: "XP Earned",
                    child: Text("XP Earned"),
                  ),
                  DropdownMenuItem(
                    value: "Amphibians Collected",
                    child: Text("Amphibians Collected"),
                  ),
                  DropdownMenuItem(
                    value: "Longest Streak",
                    child: Text("Longest Streak"),
                  ),
                ],

                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedStatistic = newValue;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(

                    barGroups: List.generate(
                      chartData.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: chartData[index],
                            width: 20,
                            color: Colors.blueGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Weekly Statistics
              const Text(
                "Weekly Statistics",
                style: TextStyle(fontSize: 24),
              ),

              const SizedBox(height: 20),

              DropdownButton<String> (
                value: selectedStatistic,

                isExpanded: true,

                items: const [
                  DropdownMenuItem(
                    value: "Tasks Completed",
                    child: Text("Tasks Completed"),
                  ),
                  DropdownMenuItem(
                    value: "Tasks Incompleted",
                    child: Text("Tasks Incomplete"),
                  ),
                  DropdownMenuItem(
                    value: "Hours Focused",
                    child: Text("Hours Focused"),
                  ),
                  DropdownMenuItem(
                    value: "Times Distracted",
                    child: Text("Times Distracted"),
                  ),
                  DropdownMenuItem(
                    value: "Currency Earned",
                    child: Text("Currency Earned"),
                  ),
                  DropdownMenuItem(
                    value: "Currency Spent",
                    child: Text("Currency Spent"),
                  ),
                  DropdownMenuItem(
                    value: "XP Earned",
                    child: Text("XP Earned"),
                  ),
                  DropdownMenuItem(
                    value: "Amphibians Collected",
                    child: Text("Amphibians Collected"),
                  ),
                  DropdownMenuItem(
                    value: "Longest Streak",
                    child: Text("Longest Streak"),
                  ),
                ],

                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedStatistic = newValue;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(

                    barGroups: List.generate(
                      chartData.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: chartData[index],
                            width: 20,
                            color: Colors.blueGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Monthly Statistics
              const Text(
                "Monthly Statistics",
                style: TextStyle(fontSize: 24),
              ),

              const SizedBox(height: 20),

              DropdownButton<String> (
                value: selectedStatistic,

                isExpanded: true,

                items: const [
                  DropdownMenuItem(
                    value: "Tasks Completed",
                    child: Text("Tasks Completed"),
                  ),
                  DropdownMenuItem(
                    value: "Tasks Incompleted",
                    child: Text("Tasks Incomplete"),
                  ),
                  DropdownMenuItem(
                    value: "Hours Focused",
                    child: Text("Hours Focused"),
                  ),
                  DropdownMenuItem(
                    value: "Times Distracted",
                    child: Text("Times Distracted"),
                  ),
                  DropdownMenuItem(
                    value: "Currency Earned",
                    child: Text("Currency Earned"),
                  ),
                  DropdownMenuItem(
                    value: "Currency Spent",
                    child: Text("Currency Spent"),
                  ),
                  DropdownMenuItem(
                    value: "XP Earned",
                    child: Text("XP Earned"),
                  ),
                  DropdownMenuItem(
                    value: "Amphibians Collected",
                    child: Text("Amphibians Collected"),
                  ),
                  DropdownMenuItem(
                    value: "Longest Streak",
                    child: Text("Longest Streak"),
                  ),
                ],

                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedStatistic = newValue;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(

                    barGroups: List.generate(
                      chartData.length,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: chartData[index],
                            width: 20,
                            color: Colors.blueGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}