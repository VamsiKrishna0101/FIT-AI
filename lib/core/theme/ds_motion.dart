import 'package:flutter/material.dart';

// MARK: - Motion Curves & Durations
class DSMotion {
  // Curves
  static const Curve snappy = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve bouncy = Curves.elasticOut;
  static const Curve gravityDrop = Curves.easeOutBack;

  // Durations
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration regular = Duration(milliseconds: 300);
  static const Duration pageTransition = Duration(milliseconds: 280);
  static const Duration drop = Duration(milliseconds: 650);
}
