import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
            backgroundColor: Colors.amber, // Set button background to gold
            foregroundColor: Colors.black, // Button text/icon color
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Bar Chart Drilldown')),
        body: ChartDrilldown(),
      ),
    );
  }
}

class ChartDrilldown extends StatefulWidget {
  @override
  _ChartDrilldownState createState() => _ChartDrilldownState();
}

class _ChartDrilldownState extends State<ChartDrilldown> {
  bool _showMainChart = true;
  int? _selectedRangeIndex;

  final List<String> mainLabels = ['0-100', '101-200', '201-300', '301-400'];
  final List<double> mainData = [150, 180, 100, 140];
  final List<Color> barColors = [
    Colors.redAccent,
    Colors.amber,
    Colors.green,
    Colors.lightBlue,
  ];
  final List<Color> subBarColors = [
    Colors.deepOrange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
  ];

  final Map<int, List<double>> subChartData = {
    0: [50, 30, 70],
    1: [60, 60, 60],
    2: [40, 30, 30],
    3: [90, 20, 30],
  };

  final Map<int, List<String>> subChartLabels = {
    0: ['A', 'B', 'C'],
    1: ['D', 'E', 'F'],
    2: ['G', 'H', 'I'],
    3: ['J', 'K', 'L'],
  };

  void _onBarTapped(int index) {
    setState(() {
      _selectedRangeIndex = index;
      _showMainChart = false;
    });
  }

  void _goBack() {
    setState(() {
      _showMainChart = true;
      _selectedRangeIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final isMainChart = child.key == const ValueKey('main');

        final offsetAnimation = Tween<Offset>(
          begin: isMainChart ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      child: _showMainChart ? _buildMainChart() : _buildSubChart(),
    );
  }

  Widget _buildMainChart() {
    return Container(
      key: const ValueKey('main'),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Ranges',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Click on bars to filter page',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: List.generate(mainData.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: mainData[index],
                        width: 100,
                        gradient: LinearGradient(
                          colors: [
                            barColors[index].withOpacity(0.7),
                            barColors[index]
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      double percentage = (mainData[groupIndex] /
                              mainData.reduce((a, b) => a + b)) *
                          100;
                      return BarTooltipItem(
                        'Students: ${mainData[groupIndex].toInt()} (${percentage.toStringAsFixed(2)}%)',
                        const TextStyle(color: Colors.black),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent &&
                        response != null &&
                        response.spot != null) {
                      _onBarTapped(response.spot!.touchedBarGroupIndex);
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < mainLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              mainLabels[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24, // Give space to show top labels
                      getTitlesWidget: (value, meta) {
                        // You can show value, or data above each bar here
                        return const Text(
                          '', // You can also write: '${value.toInt()}' if needed
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                alignment: BarChartAlignment.spaceAround,
                maxY: 400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubChart() {
    final data = subChartData[_selectedRangeIndex!]!;
    final labels = subChartLabels[_selectedRangeIndex!]!;

    return Container(
      key: const ValueKey('sub'),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
          const SizedBox(height: 16),
          Text(
            'Details for: ${mainLabels[_selectedRangeIndex!]}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Click on bars for more details',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: List.generate(data.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data[index],
                        width: 100,
                        gradient: LinearGradient(
                          colors: [
                            subBarColors[index % subBarColors.length]
                                .withOpacity(0.7),
                            subBarColors[index % subBarColors.length]
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      double percentage =
                          (data[groupIndex] / data.reduce((a, b) => a + b)) *
                              100;
                      return BarTooltipItem(
                        'Students: ${data[groupIndex].toInt()} (${percentage.toStringAsFixed(2)}%)',
                        const TextStyle(color: Colors.black),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24, // Give space to show top labels
                      getTitlesWidget: (value, meta) {
                        // You can show value, or data above each bar here
                        return const Text(
                          '', // You can also write: '${value.toInt()}' if needed
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
