// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'widgets/drilldown_bar_chart.dart';
import 'utils/app_data.dart'; // Import AppData to get chart data

void main() {
  runApp(BarChartApp());
}

class BarChartApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bar Chart Drilldown',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Bar Chart Drilldown')),
        body: DrilldownBarChart(
          initialChartData: AppData.mainChartData,
          drilldownHierarchy: AppData.drilldownHierarchy,
        ),
      ),
    );
  }
}