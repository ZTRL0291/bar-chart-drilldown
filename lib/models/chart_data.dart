// models/chart_data.dart
import 'package:flutter/material.dart';

// Enum to define the type of reveal animation
enum RevealAnimationType {
  left,
  right,
  centerSplit,
}

/// A data model to hold all information for a single bar chart level.
class ChartData {
  final List<String> labels;
  final List<List<double>> groupedData;
  final String title;
  final String description;
  final double maxY;
  final List<Color> barColors1;
  final List<Color> barColors2;
  final String id; // Unique identifier for each chart level

  ChartData({
    required this.labels,
    required this.groupedData,
    required this.title,
    required this.description,
    required this.maxY,
    required this.barColors1,
    required this.barColors2,
    required this.id,
  });
}
