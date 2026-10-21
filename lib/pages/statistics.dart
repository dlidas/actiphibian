import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String selectedStatistic = "XP Earned";

  // I'll add the weekly/monthly data versions after merging with main, this is only the daily data
  // I will also replace these with connections to the particular user's data from the db

  // Generic data while waiting for the db construction
  final List<double> xpData = [];
  final List<double> completedData = [];
  final List<double> incompleteData = [];
  final List<double> hoursFocused = [];
  final List<double> timesDistracted = [];
  final List<double> currencyEarned = [];
  final List<double> currencySpent = [];
  final List<double> amphibiansCollection = [];

  List<double> getSelectedData() {
    switch (selectedStatistic) {
      case "XP Earned":
        return xpData;

      case "Tasks Completed":
        return completedData;

      case "Tasks Incomplete":
        return incompleteData;

      case "Hours Focused":
        return hoursFocused;
      
      case "Times Distracted":
        return timesDistracted;

      case "Currency Earned":
        return currencyEarned;

      case "Currency Spent":
        return currencySpent;

      case "Amphibians Collected":
        return amphibiansCollection;

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
                    value: "XP Earned",
                    child: Text("XP Earned"),
                  ),
                  DropdownMenuItem(
                    value: "Tasks Completed",
                    child: Text("Tasks Completed"),
                  ),
                  DropdownMenuItem(
                    value: "Tasks Incomplete",
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
                    value: "Amphibians Collected",
                    child: Text("Amphibians Collected"),
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
                    value: "XP Earned",
                    child: Text("XP Earned"),
                  ),
                  DropdownMenuItem(
                    value: "Tasks Completed",
                    child: Text("Tasks Completed"),
                  ),
                  DropdownMenuItem(
                    value: "Tasks Incomplete",
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
                    value: "Amphibians Collected",
                    child: Text("Amphibians Collected"),
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
                    value: "XP Earned",
                    child: Text("XP Earned"),
                  ),
                  DropdownMenuItem(
                    value: "Tasks Completed",
                    child: Text("Tasks Completed"),
                  ),
                  DropdownMenuItem(
                    value: "Tasks Incomplete",
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
                    value: "Amphibians Collected",
                    child: Text("Amphibians Collected"),
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