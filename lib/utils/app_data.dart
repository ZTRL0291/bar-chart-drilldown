// utils/app_data.dart
import 'package:flutter/material.dart';
import '../models/chart_data.dart'; // Import ChartData

class AppData {
  // Helper function to create sub-chart data (for readability and reusability)
  static ChartData createChartData({
    required String parentId,
    required int index,
    required List<String> labels,
    required List<List<double>> data,
    required String titlePrefix,
  }) {
    // Calculate maxY dynamically based on the data
    final double calculatedMaxY =
        data.expand((e) => e).reduce((a, b) => a > b ? a : b) * 1.2;
    // Ensure maxY is at least 100 for smaller data sets
    final double finalMaxY = calculatedMaxY < 100 ? 100 : calculatedMaxY;

    // Use different color sets for different levels to visually distinguish
    List<Color> colors1;
    List<Color> colors2;

    if (parentId == 'main') {
      colors1 = List.generate(
          labels.length, (i) => Colors.primaries[(index + i) % Colors.primaries.length]);
      colors2 = List.generate(
          labels.length,
          (i) => Colors.primaries[(index + i) % Colors.primaries.length]
              .withOpacity(0.5));
    } else if (parentId.startsWith('main-') && !parentId.contains('-', parentId.indexOf('-') + 1)) { // Level 2
      colors1 = List.generate(
          labels.length, (i) => Colors.blueGrey[(index + i) * 100 % 900] ?? Colors.blueGrey);
      colors2 = List.generate(
          labels.length,
          (i) => (Colors.blueGrey[(index + i) * 100 % 900] ?? Colors.blueGrey)
              .withOpacity(0.5));
    } else { // Level 3 and deeper
      colors1 = List.generate(
          labels.length, (i) => Colors.deepPurple[(index + i) * 100 % 900] ?? Colors.deepPurple);
      colors2 = List.generate(
          labels.length,
          (i) => (Colors.deepPurple[(index + i) * 100 % 900] ?? Colors.deepPurple)
              .withOpacity(0.5));
    }

    return ChartData(
      id: '$parentId-$index', // Unique ID for each chart data instance
      labels: labels,
      groupedData: data,
      title: '$titlePrefix ${labels.first}-${labels.last}',
      description: 'Details for $titlePrefix',
      maxY: finalMaxY,
      barColors1: colors1,
      barColors2: colors2,
    );
  }

  // Define your drilldown hierarchy more explicitly using ChartData instances
  static final Map<String, Map<int, ChartData>> drilldownHierarchy = _initializeDrilldownData();

  static Map<String, Map<int, ChartData>> _initializeDrilldownData() {
    final Map<String, Map<int, ChartData>> hierarchy = {};

    // Main chart children (level 1)
    hierarchy['main'] = {
      0: createChartData(parentId: 'main', index: 0, labels: ['A', 'B', 'C'], data: [
        [50, 45], [30, 35], [70, 60]
      ], titlePrefix: 'Sub-Category for 0-100'),
      1: createChartData(parentId: 'main', index: 1, labels: ['D', 'E', 'F'], data: [
        [60, 55], [60, 65], [60, 50]
      ], titlePrefix: 'Sub-Category for 101-200'),
      2: createChartData(parentId: 'main', index: 2, labels: ['G', 'H', 'I'], data: [
        [40, 38], [30, 25], [30, 32]
      ], titlePrefix: 'Sub-Category for 201-300'),
      3: createChartData(parentId: 'main', index: 3, labels: ['J', 'K', 'L'], data: [
        [90, 85], [20, 25], [30, 30]
      ], titlePrefix: 'Sub-Category for 301-400'),
      4: createChartData(parentId: 'main', index: 4, labels: ['M', 'N', 'O'], data: [
        [70, 65], [50, 55], [80, 75]
      ], titlePrefix: 'Sub-Category for 401-500'),
      5: createChartData(parentId: 'main', index: 5, labels: ['P', 'Q', 'R'], data: [
        [45, 40], [35, 30], [40, 42]
      ], titlePrefix: 'Sub-Category for 501-600'),
    };

     // Deeper drilldown (level 2) - Example: from 'main-0' (A, B, C)
    hierarchy['main-0'] = {
      0: createChartData(parentId: 'main-0', index: 0, labels: ['A.1', 'A.2'], data: [
        [20, 18], [15, 17]
      ], titlePrefix: 'Detail for A'),
      1: createChartData(parentId: 'main-0', index: 1, labels: ['B.1', 'B.2'], data: [
        [10, 8], [8, 10]
      ], titlePrefix: 'Detail for B'),
      2: createChartData(parentId: 'main-0', index: 2, labels: ['C.1', 'C.2'], data: [
        [30, 28], [20, 22]
      ], titlePrefix: 'Detail for C'),
    };

    // Even deeper drilldown (level 3) - Example: from 'main-0-0' (A.1, A.2)
    hierarchy['main-0-0'] = {
      0: createChartData(parentId: 'main-0-0', index: 0, labels: ['A.1.1', 'A.1.2'], data: [
        [5, 4], [7, 6]
      ], titlePrefix: 'Sub-detail for A.1'),
      1: createChartData(parentId: 'main-0-0', index: 1, labels: ['A.2.1', 'A.2.2'], data: [
        [3, 2], [5, 4]
      ], titlePrefix: 'Sub-detail for A.2'),
    };
    hierarchy['main-1'] = {
      0: createChartData(parentId: 'main-1', index: 0, labels: ['D.1', 'D.2'], data: [
        [25, 22], [20, 23]
      ], titlePrefix: 'Detail for D'),
    };
    hierarchy['main-1-0'] = {
      0: createChartData(parentId: 'main-1-0', index: 0, labels: ['D.1.1', 'D.1.2'], data: [
        [10, 9], [8, 10]
      ], titlePrefix: 'Further detail for D.1'),
    };

    return hierarchy;
  }

  static final ChartData mainChartData = ChartData(
    id: 'main', // Unique ID for the main chart
    labels: [
      '0-100', '101-200', '201-300', '301-400', '401-500', '501-600'
    ],
    groupedData: [
      [150, 130], [180, 160], [100, 110], [140, 150], [200, 190], [120, 100]
    ],
    title: 'Main Attendance Ranges',
    description: 'Click on bars to drill down to sub-categories',
    maxY: 250,
    barColors1: List.generate(6, (index) => Colors.primaries[index]),
    barColors2: List.generate(6, (index) => Colors.primaries[index].withOpacity(0.5)),
  );
}