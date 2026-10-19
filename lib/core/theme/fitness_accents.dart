import 'package:flutter/material.dart';

/// Shared colours for anatomy, strength levels and training guidance.
class FitnessAccents {
  static const untrained = Color(0xFF606060);
  static const blue = Color(0xFF77ACF1);
  static const mint = Color(0xFF72C9A5);
  static const gold = Color(0xFFE5B85E);
  static const violet = Color(0xFFAC8BEA);
  static const coral = Color(0xFFE68072);
  static const bronze = Color(0xFFD89A72);

  // These hues identify anatomy; they are not an assessment of the body.
  static Color muscle(String id) => switch (id) {
        'chest' || 'shoulders' || 'calves' => coral,
        'biceps' || 'triceps' || 'forearms' => mint,
        'upper_back' ||
        'lats' ||
        'lower_back' ||
        'quads' ||
        'hamstrings' =>
          gold,
        'core' => blue,
        'glutes' => violet,
        _ => untrained,
      };

  // Suggested training emphasis, never a strength assessment.
  static Color physique(String? status) => switch (status) {
        'focus' => gold,
        'balanced' => blue,
        _ => untrained,
      };

  static Color rank(int tier) => switch (tier) {
        1 => bronze,
        2 => gold,
        3 => mint,
        4 => blue,
        5 => violet,
        _ => untrained,
      };
}
