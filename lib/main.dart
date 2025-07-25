import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(BarChartApp());
}

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

/// The common, reusable Drilldown Bar Chart Widget.
class DrilldownBarChart extends StatefulWidget {
  final ChartData initialChartData;
  final Map<String, Map<int, ChartData>> drilldownHierarchy;
  final Duration drilldownAnimationDuration;

  const DrilldownBarChart({
    Key? key,
    required this.initialChartData,
    required this.drilldownHierarchy,
    this.drilldownAnimationDuration = const Duration(milliseconds: 700),
  }) : super(key: key);

  @override
  _DrilldownBarChartState createState() => _DrilldownBarChartState();
}

class _DrilldownBarChartState extends State<DrilldownBarChart>
    with SingleTickerProviderStateMixin {
  late List<ChartData> _chartStack;
  RevealAnimationType _currentAnimationType = RevealAnimationType.centerSplit;
  late AnimationController _animationController;
  late Animation<double> _revealAnimation;
  bool _isDrillingDown = false;
  int? _hoveredGroupIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.drilldownAnimationDuration,
    );

    _revealAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _chartStack = [widget.initialChartData];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onBarTapped(int index) {
    final currentChartId = _chartStack.last.id;
    final Map<int, ChartData>? children = widget.drilldownHierarchy[currentChartId];

    if (children != null && children.containsKey(index)) {
      final ChartData nextChartData = children[index]!;

      RevealAnimationType animationType;
      if (index == 0 || index == 1) {
        animationType = RevealAnimationType.left;
      } else if (index == (_chartStack.last.groupedData.length - 1) ||
          index == (_chartStack.last.groupedData.length - 2)) {
        animationType = RevealAnimationType.right;
      } else {
        animationType = RevealAnimationType.centerSplit;
      }

      setState(() {
        _isDrillingDown = true;
        _chartStack.add(nextChartData);
        _currentAnimationType = animationType;
        _animationController.reset();
        _animationController.forward();
        _hoveredGroupIndex = null;
      });
    } else {
      print('No deeper drilldown data for this bar at ID: $currentChartId, Index: $index');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No further details available for this bar.')),
      );
    }
  }

  void _goBack() {
    if (_chartStack.length > 1) {
      setState(() {
        _isDrillingDown = false; // Immediate switch
        _chartStack.removeLast();
        _hoveredGroupIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChartData = _chartStack.last;

    return AnimatedSwitcher(
      duration: _isDrillingDown ? widget.drilldownAnimationDuration : Duration.zero,
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        if (_isDrillingDown && _animationController.status != AnimationStatus.dismissed) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, abChild) {
              return ClipPath(
                clipper: SplitRevealClipper(
                  revealFraction: _revealAnimation.value,
                  animationType: _currentAnimationType,
                  isForward: true,
                ),
                child: abChild,
              );
            },
            child: child,
          );
        }
        return child;
      },
      child: _buildChart(currentChartData),
    );
  }

  Widget _buildChart(ChartData chartData) {
    return Container(
      key: ValueKey(chartData.id),
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
          Text(
            chartData.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            chartData.description,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: TextButton.icon(
              onPressed: _chartStack.length > 1 ? _goBack : null,
              icon: Icon(
                Icons.arrow_back,
                color: _chartStack.length > 1 ? Colors.black : Colors.grey,
                size: 20.0,
              ),
              label: Text(
                'Back',
                style: TextStyle(
                  color: _chartStack.length > 1 ? Colors.black : Colors.grey,
                  fontSize: 16.0,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: List.generate(chartData.groupedData.length, (index) {
                  final groupData = chartData.groupedData[index];
                  final isHovered = index == _hoveredGroupIndex;

                  final Color bar1Color = isHovered
                      ? chartData.barColors1[index % chartData.barColors1.length]
                          .withOpacity(0.8)
                      : chartData.barColors1[index % chartData.barColors1.length];
                  final Color bar2Color = isHovered
                      ? chartData.barColors2[index % chartData.barColors2.length]
                          .withOpacity(0.8)
                      : chartData.barColors2[index % chartData.barColors2.length];
                  const double barWidth = 40;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: groupData[0],
                        color: bar1Color,
                        width: barWidth,
                        borderRadius: BorderRadius.zero,
                        borderSide: isHovered
                            ? BorderSide(
                                color: Colors.black.withOpacity(0.5), width: 2)
                            : BorderSide.none,
                      ),
                      BarChartRodData(
                        toY: groupData[1],
                        color: bar2Color,
                        width: barWidth,
                        borderRadius: BorderRadius.zero,
                        borderSide: isHovered
                            ? BorderSide(
                                color: Colors.black.withOpacity(0.5), width: 2)
                            : BorderSide.none,
                      ),
                    ],
                    barsSpace: 8,
                  );
                }),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final currentGroupData = chartData.groupedData[groupIndex];
                      final actual = currentGroupData[0].toInt();
                      final target = currentGroupData[1].toInt();
                      return BarTooltipItem(
                        'Actual: $actual\nTarget: $target',
                        const TextStyle(color: Colors.black),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event.isInterestedForInteractions) {
                      setState(() {
                        _hoveredGroupIndex = response?.spot?.touchedBarGroupIndex;
                      });
                    } else {
                      setState(() {
                        _hoveredGroupIndex = null;
                      });
                    }
                    if (event is FlTapUpEvent && response?.spot != null) {
                      _onBarTapped(response!.spot!.touchedBarGroupIndex);
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles:  AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles:  AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < chartData.labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              chartData.labels[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles:  AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        return Text('', style: TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                alignment: BarChartAlignment.spaceAround,
                maxY: chartData.maxY,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendColor(color: chartData.barColors1[0], text: 'Actual'),
                const SizedBox(width: 20),
                _LegendColor(color: chartData.barColors2[0], text: 'Target'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Clipper to achieve dynamic reveal effect based on type
class SplitRevealClipper extends CustomClipper<Path> {
  final double revealFraction;
  final RevealAnimationType animationType;
  final bool isForward;

  SplitRevealClipper({
    required this.revealFraction,
    required this.animationType,
    required this.isForward,
  });

  @override
  Path getClip(Size size) {
    final double effectiveReveal = revealFraction;

    final path = Path();
    final halfWidth = size.width / 2;

    switch (animationType) {
      case RevealAnimationType.left:
        path.addRect(Rect.fromLTWH(
          0,
          0,
          size.width * effectiveReveal,
          size.height,
        ));
        break;
      case RevealAnimationType.right:
        path.addRect(Rect.fromLTWH(
          size.width - (size.width * effectiveReveal),
          0,
          size.width * effectiveReveal,
          size.height,
        ));
        break;
      case RevealAnimationType.centerSplit:
        path.addRect(Rect.fromLTWH(
          halfWidth - (halfWidth * effectiveReveal),
          0,
          halfWidth * effectiveReveal,
          size.height,
        ));

        path.addRect(Rect.fromLTWH(
          halfWidth,
          0,
          halfWidth * effectiveReveal,
          size.height,
        ));
        break;
    }
    return path;
  }

  @override
  bool shouldReclip(covariant SplitRevealClipper oldClipper) {
    return oldClipper.revealFraction != revealFraction ||
        oldClipper.animationType != animationType ||
        oldClipper.isForward != isForward;
  }
}

// Helper widget for displaying a legend item
class _LegendColor extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendColor({
    Key? key,
    required this.color,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

class BarChartApp extends StatelessWidget {
  // Helper function to create sub-chart data (for readability and reusability)
  // Made static to be accessible without an instance of BarChartApp
  static ChartData _createChartData({
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
  // Made static so it can be defined once and passed.
  static final Map<String, Map<int, ChartData>> _drilldownHierarchy = _initializeDrilldownData();

  static Map<String, Map<int, ChartData>> _initializeDrilldownData() {
    final Map<String, Map<int, ChartData>> hierarchy = {};

    // Main chart children (level 1)
    hierarchy['main'] = {
      0: _createChartData(parentId: 'main', index: 0, labels: ['A', 'B', 'C'], data: [
        [50, 45], [30, 35], [70, 60]
      ], titlePrefix: 'Sub-Category for 0-100'),
      1: _createChartData(parentId: 'main', index: 1, labels: ['D', 'E', 'F'], data: [
        [60, 55], [60, 65], [60, 50]
      ], titlePrefix: 'Sub-Category for 101-200'),
      2: _createChartData(parentId: 'main', index: 2, labels: ['G', 'H', 'I'], data: [
        [40, 38], [30, 25], [30, 32]
      ], titlePrefix: 'Sub-Category for 201-300'),
      3: _createChartData(parentId: 'main', index: 3, labels: ['J', 'K', 'L'], data: [
        [90, 85], [20, 25], [30, 30]
      ], titlePrefix: 'Sub-Category for 301-400'),
      4: _createChartData(parentId: 'main', index: 4, labels: ['M', 'N', 'O'], data: [
        [70, 65], [50, 55], [80, 75]
      ], titlePrefix: 'Sub-Category for 401-500'),
      5: _createChartData(parentId: 'main', index: 5, labels: ['P', 'Q', 'R'], data: [
        [45, 40], [35, 30], [40, 42]
      ], titlePrefix: 'Sub-Category for 501-600'),
    };

    // Deeper drilldown (level 2) - Example: from 'main-0' (A, B, C)
    hierarchy['main-0'] = {
      0: _createChartData(parentId: 'main-0', index: 0, labels: ['A.1', 'A.2'], data: [
        [20, 18], [15, 17]
      ], titlePrefix: 'Detail for A'),
      1: _createChartData(parentId: 'main-0', index: 1, labels: ['B.1', 'B.2'], data: [
        [10, 8], [8, 10]
      ], titlePrefix: 'Detail for B'),
      2: _createChartData(parentId: 'main-0', index: 2, labels: ['C.1', 'C.2'], data: [
        [30, 28], [20, 22]
      ], titlePrefix: 'Detail for C'),
    };

    // Even deeper drilldown (level 3) - Example: from 'main-0-0' (A.1, A.2)
    hierarchy['main-0-0'] = {
      0: _createChartData(parentId: 'main-0-0', index: 0, labels: ['A.1.1', 'A.1.2'], data: [
        [5, 4], [7, 6]
      ], titlePrefix: 'Sub-detail for A.1'),
      1: _createChartData(parentId: 'main-0-0', index: 1, labels: ['A.2.1', 'A.2.2'], data: [
        [3, 2], [5, 4]
      ], titlePrefix: 'Sub-detail for A.2'),
    };
    hierarchy['main-1'] = {
      0: _createChartData(parentId: 'main-1', index: 0, labels: ['D.1', 'D.2'], data: [
        [25, 22], [20, 23]
      ], titlePrefix: 'Detail for D'),
    };
    hierarchy['main-1-0'] = {
      0: _createChartData(parentId: 'main-1-0', index: 0, labels: ['D.1.1', 'D.1.2'], data: [
        [10, 9], [8, 10]
      ], titlePrefix: 'Further detail for D.1'),
    };

    return hierarchy;
  }

  static final ChartData _mainChartData = ChartData(
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
          initialChartData: _mainChartData,
          drilldownHierarchy: _drilldownHierarchy,
        ),
      ),
    );
  }
}