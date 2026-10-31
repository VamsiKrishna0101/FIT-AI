import 'package:flutter/material.dart';

// MARK: - Motion Curves & Durations
class DSMotion {
  // Curves
  static const Curve effects = Curves.easeOutCubic;
  // AnimatedSwitcher reverses its outgoing controller. Mirror the easing so
  // outgoing and incoming content never remain fully visible together.
  static const Curve exit = FlippedCurve(effects);
  static const Curve contentIn = Interval(.2, 1, curve: effects);
  static const Curve contentOut = Interval(.7, 1, curve: exit);
  static const Curve tabOut = Interval(0, .3, curve: effects);
  static const Curve snappy = effects;
  static const Curve standard = effects;
  static const Curve bouncy = effects;
  static const Curve gravityDrop = effects;

  // Durations
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration regular = pageTransition;
  static const Duration pageTransition = Duration(milliseconds: 280);
  static const Duration drop = reveal;
  static const Duration press = Duration(milliseconds: 120);
  static const Duration selection = fast;
  static const Duration reveal = pageTransition;
  static const Duration chart = Duration(milliseconds: 420);
  static const Duration illustration = Duration(milliseconds: 840);
  static const Duration feedback = selection;

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration duration(BuildContext context, Duration value) =>
      reduced(context) ? Duration.zero : value;

  static AnimationStyle sheetStyle(BuildContext context) => reduced(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          curve: effects,
          reverseCurve: exit,
          duration: pageTransition,
          reverseDuration: pageTransition);

  static AnimationStyle dialogStyle(BuildContext context) => reduced(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          curve: effects,
          reverseCurve: exit,
          duration: regular,
          reverseDuration: regular);

  static double barProgress(double progress, int index, int count) {
    final delay = count <= 1 ? 0.0 : index / (count - 1) * .12;
    return effects
        .transform(((progress - delay) / (1 - delay)).clamp(0.0, 1.0));
  }
}
