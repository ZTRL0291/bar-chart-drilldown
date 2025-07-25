// widgets/drilldown_bar_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/chart_data.dart';
import '../providers/drilldown_chart_provider.dart';
import 'custom_clippers.dart'; // Import your custom clippers

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
  late DrilldownChartProvider _provider;

  @override
  void initState() {
    super.initState();
    // Initialize the provider with required data.
    // Ensure this is called once.
    _provider = DrilldownChartProvider(
      initialChartData: widget.initialChartData,
      drilldownHierarchy: widget.drilldownHierarchy,
      drilldownAnimationDuration: widget.drilldownAnimationDuration,
    );
    // Initialize the animation controller within the provider
    _provider.initAnimationController(this);
  }

  @override
  void dispose() {
    // Dispose the animation controller when the widget is disposed
    _provider.disposeAnimationController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DrilldownChartProvider>.value(
      value: _provider,
      child: Consumer<DrilldownChartProvider>(
        builder: (context, provider, child) {
          final currentChartData = provider.currentChartData;

          return AnimatedSwitcher(
            duration: provider.isDrillingDown
                ? provider.drilldownAnimationDuration
                : Duration.zero,
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
              // Only apply the clip path animation when drilling down
              // and the animation controller is active.
              if (provider.isDrillingDown &&
                  provider.revealAnimation != null &&
                  provider.animationController?.status != AnimationStatus.dismissed) {
                return AnimatedBuilder(
                  animation: provider.revealAnimation!,
                  builder: (context, abChild) {
                    return ClipPath(
                      clipper: SplitRevealClipper(
                        revealFraction: provider.revealAnimation!.value,
                        animationType: provider.currentAnimationType,
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
            child: _buildChart(currentChartData, provider),
          );
        },
      ),
    );
  }

  Widget _buildChart(
      ChartData chartData, DrilldownChartProvider provider) {
    return Container(
      key: ValueKey(chartData.id), // Key is crucial for AnimatedSwitcher
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
              onPressed: provider.canGoBack ? provider.goBack : null,
              icon: Icon(
                Icons.arrow_back,
                color: provider.canGoBack ? Colors.black : Colors.grey,
                size: 20.0,
              ),
              label: Text(
                'Back',
                style: TextStyle(
                  color: provider.canGoBack ? Colors.black : Colors.grey,
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
                  final isHovered = index == provider.hoveredGroupIndex;

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
                      provider.updateHoveredGroupIndex(response?.spot?.touchedBarGroupIndex);
                    } else {
                      provider.updateHoveredGroupIndex(null);
                    }
                    if (event is FlTapUpEvent && response?.spot != null) {
                      provider.onBarTapped(response!.spot!.touchedBarGroupIndex, context);
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles: AxisTitles(
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