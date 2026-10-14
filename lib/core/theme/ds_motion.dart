import 'package:flutter/material.dart';

// MARK: - Motion Curves & Durations
class DSMotion {
  // Curves
  static const Curve snappy = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve bouncy = Curves.easeOutBack;
  static const Curve gravityDrop = Curves.easeOutCubic;
  static const Curve effects = Cubic(.2, 0, 0, 1);
  static final SpringDescription pressSpring =
      SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 550,
    ratio: .85,
  );

  // Durations
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration regular = Duration(milliseconds: 300);
  static const Duration pageTransition = Duration(milliseconds: 280);
  static const Duration drop = Duration(milliseconds: 650);
  static const Duration press = Duration(milliseconds: 120);
  static const Duration selection = Duration(milliseconds: 220);
  static const Duration reveal = Duration(milliseconds: 340);
  static const Duration chart = Duration(milliseconds: 560);
  static const Duration feedback = Duration(milliseconds: 260);

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration duration(BuildContext context, Duration value) =>
      reduced(context) ? Duration.zero : value;

  static AnimationStyle sheetStyle(BuildContext context) => reduced(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(duration: reveal, reverseDuration: selection);

  static AnimationStyle dialogStyle(BuildContext context) => reduced(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(duration: selection, reverseDuration: press);

  static double barProgress(double progress, int index, int count) {
    final delay = count <= 1 ? 0.0 : index / (count - 1) * .12;
    return effects
        .transform(((progress - delay) / (1 - delay)).clamp(0.0, 1.0));
  }
}
