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

// Enum to define the type of reveal animation
enum RevealAnimationType {
  left,
  right,
  centerSplit,
}

class ChartDrilldown extends StatefulWidget {
  @override
  _ChartDrilldownState createState() => _ChartDrilldownState();
}

class _ChartDrilldownState extends State<ChartDrilldown>
    with SingleTickerProviderStateMixin {
  bool _showMainChart = true;
  int? _selectedRangeIndex;
  RevealAnimationType _currentAnimationType =
      RevealAnimationType.centerSplit; // Default

  late AnimationController _animationController;
  late Animation<double> _blackOverlayAnimation; // For the fade to black effect
  late Animation<double>
      _revealAnimation; // For the incoming sub-chart reveal (can be left, right, or split)

  // --- Updated Data Structures for Grouped Bars ---
  final List<String> mainLabels = [
    '0-100',
    '101-200',
    '201-300',
    '301-400',
    '401-500',
    '501-600'
  ];
  // List of lists for main chart data (e.g., [Actual, Target] for each group)
  final List<List<double>> mainGroupedData = [
    [150, 130], // For '0-100' (Actual, Target)
    [180, 160], // For '101-200'
    [100, 110], // For '201-300'
    [140, 150], // For '301-400'
    [200, 190], // For '401-500'
    [120, 100], // For '501-600'
  ];

  final List<Color> barColors1 = [
    Colors.redAccent,
    Colors.amber,
    Colors.green,
    Colors.lightBlue,
    Colors.purpleAccent,
    Colors.orangeAccent,
  ];
  final List<Color> barColors2 = [
    Colors.redAccent.shade100, // Lighter shade for the second bar
    Colors.amber.shade100,
    Colors.green.shade100,
    Colors.lightBlue.shade100,
    Colors.purpleAccent.shade100,
    Colors.orangeAccent.shade100,
  ];

  // Map of lists of lists for sub-chart data
  final Map<int, List<List<double>>> subChartGroupedData = {
    0: [
      [50, 45],
      [30, 35],
      [70, 60]
    ],
    1: [
      [60, 55],
      [60, 65],
      [60, 50]
    ],
    2: [
      [40, 38],
      [30, 25],
      [30, 32]
    ],
    3: [
      [90, 85],
      [20, 25],
      [30, 30]
    ],
    4: [
      [70, 65],
      [50, 55],
      [80, 75]
    ],
    5: [
      [45, 40],
      [35, 30],
      [40, 42]
    ],
  };

  final Map<int, List<String>> subChartLabels = {
    0: ['A', 'B', 'C'],
    1: ['D', 'E', 'F'],
    2: ['G', 'H', 'I'],
    3: ['J', 'K', 'L'],
    4: ['M', 'N', 'O'],
    5: ['P', 'Q', 'R'],
  };
  // --- End Updated Data Structures ---

  // --- State variable for the currently hovered group index ---
  int? _hoveredGroupIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Total animation duration
    );

    _blackOverlayAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeIn),
      ),
    );

    _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onBarTapped(int index) {
    RevealAnimationType animationType;
    if (index == 0 || index == 1) {
      animationType = RevealAnimationType.left;
    } else if (index == mainGroupedData.length - 1 ||
        index == mainGroupedData.length - 2) {
      animationType = RevealAnimationType.right;
    } else {
      animationType = RevealAnimationType.centerSplit;
    }

    setState(() {
      _selectedRangeIndex = index;
      _currentAnimationType = animationType;
      _showMainChart = false;
      _animationController.forward(from: 0.0);
    });
  }

  void _goBack() {
    setState(() {
      _showMainChart = true;
      _animationController.reverse(from: 1.0).then((_) {
        _selectedRangeIndex = null;
        _hoveredGroupIndex = null; // Reset hovered index when going back
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
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
        final isMainChart = child.key == const ValueKey('main');

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            if (isMainChart) {
              return Stack(
                children: [
                  child,
                  IgnorePointer(
                    child: Opacity(
                      opacity: _blackOverlayAnimation.value,
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              final bool isAnimationForward =
                  _animationController.status == AnimationStatus.forward ||
                      _animationController.status == AnimationStatus.completed;

              return ClipPath(
                clipper: SplitRevealClipper(
                  revealFraction: _revealAnimation.value,
                  animationType: _currentAnimationType,
                  isForward: isAnimationForward,
                ),
                child: child,
              );
            }
          },
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
           // Adjusted for consistent spacing
          const Text(
            'Click on bars to filter page',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          // Back button for consistency, but disabled on the main chart
          SizedBox(
            height: 40, // Fixed height for consistent spacing
            child: TextButton.icon(
              onPressed: null, // Initially disabled
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.grey,
                size: 20.0,
              ),
              label: const Text(
                'Back',
                style: TextStyle(
                  color: Colors.grey,
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
                barGroups: List.generate(mainGroupedData.length, (index) {
                  final groupData = mainGroupedData[index];
                  // Determine if the current group is hovered
                  final isHovered = index == _hoveredGroupIndex;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: groupData[0], // First bar (e.g., Actual)
                        color: isHovered
                            ? barColors1[index].withOpacity(0.8)
                            : barColors1[index],
                        width: isHovered ? 40 : 40, // Slightly larger on hover
                        // --- REMOVE CIRCULAR CORNERS HERE ---
                        borderRadius: BorderRadius.zero, // Make corners sharp
                        // --- END REMOVE CIRCULAR CORNERS ---
                        borderSide: isHovered
                            ? BorderSide(
                                color: Colors.black.withOpacity(0.5), width: 2)
                            : BorderSide.none,
                      ),
                      BarChartRodData(
                        toY: groupData[1], // Second bar (e.g., Target)
                        color: isHovered
                            ? barColors2[index].withOpacity(0.8)
                            : barColors2[index],
                        width: isHovered ? 40 : 40, // Slightly larger on hover
                        // --- REMOVE CIRCULAR CORNERS HERE ---
                        borderRadius: BorderRadius.zero, // Make corners sharp
                        // --- END REMOVE CIRCULAR CORNERS ---
                        borderSide: isHovered
                            ? BorderSide(
                                color: Colors.black.withOpacity(0.5), width: 2)
                            : BorderSide.none,
                      ),
                    ],
                    barsSpace: 8, // Space between the two bars in a group
                  );
                }),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final currentGroupData = mainGroupedData[groupIndex];
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
                        _hoveredGroupIndex =
                            response?.spot?.touchedBarGroupIndex;
                      });
                    } else {
                      setState(() {
                        _hoveredGroupIndex = null; // Reset when not hovered
                      });
                    }
                    if (event is FlTapUpEvent && response?.spot != null) {
                      _onBarTapped(response!.spot!.touchedBarGroupIndex);
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  // --- REMOVE BOTH Y-AXIS LABELS (LEFT AND RIGHT) ---
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false, // Disable left titles
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false, // Disable right titles
                    ),
                  ),
                  // --- END REMOVE Y-AXIS LABELS ---
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
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        return const Text('', style: TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                alignment: BarChartAlignment.spaceAround,
                maxY: 250, // Max Y should be adjusted based on your new data
              ),
            ),
          ),
          // Add a legend if desired for the two bars
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _LegendColor(color: Colors.redAccent, text: 'Actual'),
                const SizedBox(width: 20),
                _LegendColor(color: Colors.redAccent.shade100, text: 'Target'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Define subBarColors for sub-chart bars
  final List<Color> subBarColors = [
    Colors.deepOrange,
    Colors.teal,
    Colors.indigo,
    Colors.pinkAccent,
    Colors.cyan,
    Colors.lime,
  ];

  Widget _buildSubChart() {
    if (_selectedRangeIndex == null) {
      return const SizedBox.shrink();
    }
    final data = subChartGroupedData[_selectedRangeIndex!]!;
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
          const Text(
            'Attendance Ranges',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Click on bars for more details',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 4), // Adjusted for consistent spacing
          // Back button on the sub-chart
          SizedBox(
            height: 40, // Fixed height for consistent spacing
            child: TextButton.icon(
              onPressed: _goBack,
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 20.0,
              ),
              label: const Text(
                'Back',
                style: TextStyle(
                  color: Colors.black,
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
                barGroups: List.generate(data.length, (index) {
                  final groupData = data[index];
                  // Determine if the current group is hovered
                  final isHovered = index == _hoveredGroupIndex;

                  // Apply highlight effect here
                  final Color bar1Color = isHovered
                      ? subBarColors[index % subBarColors.length]
                          .withOpacity(0.8)
                      : subBarColors[index % subBarColors.length];
                  final Color bar2Color = isHovered
                      ? subBarColors[index % subBarColors.length]
                          .withOpacity(0.4)
                      : subBarColors[index % subBarColors.length]
                          .withOpacity(0.5);
                  final double barWidth =
                      isHovered ? 40 : 40; // Slightly larger on hover

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: groupData[0], // First bar (e.g., Actual)
                        color: bar1Color,
                        width: barWidth,
                        // --- REMOVE CIRCULAR CORNERS HERE ---
                        borderRadius: BorderRadius.zero, // Make corners sharp
                        // --- END REMOVE CIRCULAR CORNERS ---
                        borderSide: isHovered
                            ? BorderSide(
                                color: Colors.black.withOpacity(0.5), width: 2)
                            : BorderSide.none,
                      ),
                      BarChartRodData(
                        toY: groupData[1], // Second bar (e.g., Target)
                        color: bar2Color,
                        width: barWidth,
                        // --- REMOVE CIRCULAR CORNERS HERE ---
                        borderRadius: BorderRadius.zero, // Make corners sharp
                        // --- END REMOVE CIRCULAR CORNERS ---
                        borderSide: isHovered
                            ? BorderSide(
                                color: Colors.black.withOpacity(0.5), width: 2)
                            : BorderSide.none,
                      ),
                    ],
                    barsSpace: 8, // Space between bars in a group
                  );
                }),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final currentGroupData = data[groupIndex];
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
                        _hoveredGroupIndex =
                            response?.spot?.touchedBarGroupIndex;
                      });
                    } else {
                      setState(() {
                        _hoveredGroupIndex = null; // Reset when not hovered
                      });
                    }
                    // No tap action for sub-chart based on your current code
                  },
                ),
                titlesData: FlTitlesData(
                  // --- REMOVE BOTH Y-AXIS LABELS (LEFT AND RIGHT) ---
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false, // Disable left titles
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false, // Disable right titles
                    ),
                  ),
                  // --- END REMOVE Y-AXIS LABELS ---
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
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        return const Text('', style: TextStyle(fontSize: 10));
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
          // Add a legend if desired for the two bars
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _LegendColor(color: Colors.deepOrange, text: 'Actual'),
                const SizedBox(width: 20),
                _LegendColor(
                    color: Colors.deepOrange.withOpacity(0.5), text: 'Target'),
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
  final RevealAnimationType animationType; // New parameter
  final bool isForward; // Crucial for correct clipping after animation

  SplitRevealClipper({
    required this.revealFraction,
    required this.animationType,
    required this.isForward,
  });

  @override
  Path getClip(Size size) {
    final double effectiveRevealFraction =
        isForward ? revealFraction : (1.0 - revealFraction);

    final path = Path();
    final halfWidth = size.width / 2;

    switch (animationType) {
      case RevealAnimationType.left:
        path.addRect(Rect.fromLTWH(
          0,
          0,
          size.width * effectiveRevealFraction,
          size.height,
        ));
        break;
      case RevealAnimationType.right:
        path.addRect(Rect.fromLTWH(
          size.width - (size.width * effectiveRevealFraction),
          0,
          size.width * effectiveRevealFraction,
          size.height,
        ));
        break;
      case RevealAnimationType.centerSplit:
        path.addRect(Rect.fromLTWH(
          halfWidth - (halfWidth * effectiveRevealFraction),
          0,
          halfWidth * effectiveRevealFraction,
          size.height,
        ));

        path.addRect(Rect.fromLTWH(
          halfWidth,
          0,
          halfWidth * effectiveRevealFraction,
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