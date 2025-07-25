// providers/drilldown_chart_provider.dart
import 'package:flutter/material.dart';
import '../models/chart_data.dart'; // Import the ChartData model

class DrilldownChartProvider with ChangeNotifier {
  final ChartData initialChartData;
  final Map<String, Map<int, ChartData>> drilldownHierarchy;
  final Duration drilldownAnimationDuration;

  late List<ChartData> _chartStack;
  RevealAnimationType _currentAnimationType = RevealAnimationType.centerSplit;
  bool _isDrillingDown = false;
  int? _hoveredGroupIndex;

  // Animation related properties
  AnimationController? _animationController;
  Animation<double>? _revealAnimation;

  // ADD THESE GETTERS to expose the private animation controllers
  AnimationController? get animationController => _animationController;
  Animation<double>? get revealAnimation => _revealAnimation;


  DrilldownChartProvider({
    required this.initialChartData,
    required this.drilldownHierarchy,
    this.drilldownAnimationDuration = const Duration(milliseconds: 700),
  }) {
    _chartStack = [initialChartData];
  }

  // Getters to access the state
  List<ChartData> get chartStack => _chartStack;
  ChartData get currentChartData => _chartStack.last;
  RevealAnimationType get currentAnimationType => _currentAnimationType;
  bool get isDrillingDown => _isDrillingDown;
  int? get hoveredGroupIndex => _hoveredGroupIndex;
  // Removed `revealAnimation` getter from here as it's already added above
  bool get canGoBack => _chartStack.length > 1;

  // Initialize and dispose animation controller
  void initAnimationController(TickerProvider vsync) {
    _animationController = AnimationController(
      vsync: vsync,
      duration: drilldownAnimationDuration,
    );
    _revealAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    );
  }

  void disposeAnimationController() {
    _animationController?.dispose();
    _animationController = null;
    _revealAnimation = null;
  }

  /// Handles drilling down into a new chart level.
  void onBarTapped(int index, BuildContext context) {
    final currentChartId = _chartStack.last.id;
    final Map<int, ChartData>? children = drilldownHierarchy[currentChartId];

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

      _isDrillingDown = true;
      _chartStack.add(nextChartData);
      _currentAnimationType = animationType;
      _hoveredGroupIndex = null; // Clear hover state on drilldown

      // Start animation
      _animationController?.reset();
      _animationController?.forward().whenComplete(() {
        _isDrillingDown = false; // Reset drilling state after animation
        notifyListeners(); // Notify listeners again to ensure UI reflects final state
      });
      notifyListeners(); // Notify listeners to start the animation
    } else {
      print('No deeper drilldown data for this bar at ID: $currentChartId, Index: $index');
      // Show a SnackBar using the provided context
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No further details available for this bar.')),
      );
    }
  }

  /// Handles navigating back to the previous chart level.
  void goBack() {
    if (_chartStack.length > 1) {
      _isDrillingDown = false; // Immediate switch for going back
      _chartStack.removeLast();
      _hoveredGroupIndex = null; // Clear hover state on going back
      notifyListeners();
    }
  }

  /// Updates the hovered bar group index for visual feedback.
  void updateHoveredGroupIndex(int? index) {
    if (_hoveredGroupIndex != index) {
      _hoveredGroupIndex = index;
      notifyListeners();
    }
  }
}