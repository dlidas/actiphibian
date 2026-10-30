import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/data/user_manager.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String selectedStatistic = "XP";

  int xp = 0;
  int balance = 0;
  int tasksCreated = 0;
  int tasksCompleted = 0;
  int tasksIncompleted = 0;
  int amphibianCount = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStatisticData();
  }

  // Gets the statistical data from the database to display on the bar charts
  Future<void> loadStatisticData() async {
    final int? id = context.read<UserManager>().user.id;
    final user = context.read<UserManager>().user;

    if (id == null) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      return;
    }

    final xpTotal = user.xp;
    final balanceTotal = user.balance;
    final taskCount = await LocalDb.getTaskCount();
    final completeCount = await LocalDb.getCompleteTaskCount();
    final incompleteCount = await LocalDb.getIncompleteTaskCount();
    final amphibianTotal = await LocalDb.getTotalAmphibians();

    if (!mounted) return;

    setState(() {
      xp = xpTotal;
      balance = balanceTotal;
      tasksCreated = taskCount;
      tasksCompleted = completeCount;
      tasksIncompleted = incompleteCount;
      amphibianCount = amphibianTotal;
      isLoading = false;
    });
  }

  // Determines which statistical data will be displayed
  // if their corrosponding choice is selected in the dropdown
  List<double> getSelectedData() {
    switch (selectedStatistic) {
      case "XP":
        return [xp.toDouble()];
      case "Balance":
        return [balance.toDouble()];
      case "Tasks Created":
        return [tasksCreated.toDouble()];
      case "Tasks Completed":
        return [tasksCompleted.toDouble()];
      case "Tasks Not Completed":
        return [tasksIncompleted.toDouble()];
      case "Total Amphibians":
        return [amphibianCount.toDouble()];
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
              const Text(
                "Choose Statistic",
                style: TextStyle(fontSize: 24),
              ),
              // The dropdown allows a user to select which statistic they wish to see
              DropdownButton<String>(
                value: selectedStatistic,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: "XP",
                    child: Text("XP"),
                  ),
                  DropdownMenuItem(
                    value: "Balance",
                    child: Text("Balance"),
                  ),
                  DropdownMenuItem(
                    value: "Tasks Created",
                    child: Text("Tasks Created"),
                  ),
                  DropdownMenuItem(
                    value: "Tasks Completed",
                    child: Text("Tasks Completed"),
                  ),
                  DropdownMenuItem(
                    value: "Tasks Not Completed",
                    child: Text("Tasks Not Completed"),
                  ),
                  DropdownMenuItem(
                    value: "Total Amphibians",
                    child: Text("Total Amphibians"),
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

              // Daily Statistics display using a bar chart
              const Text(
                "Daily Statistics",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(selectedStatistic),
                        axisNameSize: 30,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text("Days"),
                        axisNameSize: 30,
                        sideTitles: SideTitles(
                          showTitles: true,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    barGroups: List.generate(
                      chartData.length,
                      (index) => BarChartGroupData(
                        x: index + 1,
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

              // Weekly Statistics display using a bar chart
              const Text(
                "Weekly Statistics",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(selectedStatistic),
                        axisNameSize: 30,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text("Days"),
                        axisNameSize: 30,
                        sideTitles: SideTitles(
                          showTitles: true,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    barGroups: List.generate(
                      7,
                      (index) => BarChartGroupData(
                        x: index + 1,
                        barRods: [
                          BarChartRodData(
                            toY: index < chartData.length
                                ? chartData[index]
                                : 0.0,
                            width: 20,
                            color: Colors.blueGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Monthly Statistics display using a bar chart
              const Text(
                "Monthly Statistics",
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(selectedStatistic),
                        axisNameSize: 30,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text("Days"),
                        axisNameSize: 30,
                        sideTitles: SideTitles(
                          showTitles: true,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    // The list will be limited to 7, same as the weekly, since the numbers overflow otherwise
                    barGroups: List.generate(
                      7,
                      (index) => BarChartGroupData(
                        x: index + 1,
                        barRods: [
                          BarChartRodData(
                            toY: index < chartData.length
                                ? chartData[index]
                                : 0.0,
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