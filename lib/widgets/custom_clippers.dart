// widgets/custom_clippers.dart
import 'package:flutter/material.dart';
import '../models/chart_data.dart'; // Import RevealAnimationType

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