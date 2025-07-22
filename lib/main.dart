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
  RevealAnimationType _currentAnimationType = RevealAnimationType.centerSplit; // Default

  late AnimationController _animationController;
  late Animation<double> _blackOverlayAnimation; // For the fade to black effect
  late Animation<double>
      _revealAnimation; // For the incoming sub-chart reveal (can be left, right, or split)

  final List<String> mainLabels = ['0-100', '101-200', '201-300', '301-400', '401-500', '501-600']; // Added more for testing right side
  final List<double> mainData = [150, 180, 100, 140, 200, 120]; // Added more for testing right side
  final List<Color> barColors = [
    Colors.redAccent,
    Colors.amber,
    Colors.green,
    Colors.lightBlue,
    Colors.purpleAccent,
    Colors.orangeAccent,
  ];
  final List<Color> subBarColors = [
    Colors.deepOrange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
    Colors.blueGrey,
  ];

  final Map<int, List<double>> subChartData = {
    0: [50, 30, 70],
    1: [60, 60, 60],
    2: [40, 30, 30],
    3: [90, 20, 30],
    4: [70, 50, 80],
    5: [45, 35, 40],
  };

  final Map<int, List<String>> subChartLabels = {
    0: ['A', 'B', 'C'],
    1: ['D', 'E', 'F'],
    2: ['G', 'H', 'I'],
    3: ['J', 'K', 'L'],
    4: ['M', 'N', 'O'],
    5: ['P', 'Q', 'R'],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Total animation duration
    );

    // Animates the black overlay on the main chart
    _blackOverlayAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5,
            curve: Curves.easeIn), // Fade in black in the first half
      ),
    );

    // Animates the revealing of the sub chart (reveal fraction for clipping)
    _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0,
            curve: Curves.easeOut), // Reveal sub chart in the second half
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
    } else if (index == mainData.length - 1 || index == mainData.length - 2) {
      animationType = RevealAnimationType.right;
    } else {
      animationType = RevealAnimationType.centerSplit;
    }

    setState(() {
      _selectedRangeIndex = index;
      _currentAnimationType = animationType; // Set the determined animation type
      _showMainChart = false;
      _animationController.forward(from: 0.0); // Start animation forward
    });
  }

  void _goBack() {
    setState(() {
      _showMainChart = true;
      _animationController.reverse(from: 1.0).then((_) {
        // Only nullify _selectedRangeIndex after reverse animation completes
        _selectedRangeIndex = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1000),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren, // Place outgoing children (main chart) behind
            if (currentChild != null) currentChild, // Place incoming child (sub chart) on top
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final isMainChart = child.key == const ValueKey('main');

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            if (isMainChart) {
              // This is the outgoing main chart. Apply a black overlay.
              return Stack(
                children: [
                  child, // The main chart itself
                  IgnorePointer(
                    // Prevent interaction with the fading overlay
                    child: Opacity(
                      opacity: _blackOverlayAnimation.value,
                      child: Container(
                        color: Colors.black, // The black overlay
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // This is the incoming sub-chart. Apply the determined reveal.
              // This flag ensures the clipper knows if it's animating forward (revealing)
              // or backward (contracting), and stays fully revealed when completed.
              final bool isAnimationForward = _animationController.status == AnimationStatus.forward ||
                                              _animationController.status == AnimationStatus.completed;

              return ClipPath(
                clipper: SplitRevealClipper(
                  revealFraction: _revealAnimation.value,
                  animationType: _currentAnimationType, // Pass the animation type
                  isForward: isAnimationForward, // Essential for proper clipping after completion
                ),
                child: child,
              );
            }
          },
          child:
              child, // The child here will be either _buildMainChart() or _buildSubChart()
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
    // Ensure _selectedRangeIndex is not null before using it
    if (_selectedRangeIndex == null) {
      return const SizedBox.shrink(); // Or a loading indicator, or error message
    }
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
    // The effective fraction depends on whether we are revealing (forward) or contracting (reverse)
    final double effectiveRevealFraction = isForward ? revealFraction : (1.0 - revealFraction);

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
      // Left half (expands from center to left)
        path.addRect(Rect.fromLTWH(
          halfWidth - (halfWidth * effectiveRevealFraction),
          0,
          halfWidth * effectiveRevealFraction,
          size.height,
        ));

        // Right half (expands from center to right)
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
