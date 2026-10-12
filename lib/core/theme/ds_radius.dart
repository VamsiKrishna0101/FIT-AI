import 'package:flutter/material.dart';

// MARK: - Squircle & Capsule Corner Radii
class DSRadius {
  static const double chip = 12.0;
  static const double card = 24.0;
  static const double hero = 32.0;
  static const double modal = 36.0;
  static const double capsule = 999.0;

  static BorderRadius get chipRadius => BorderRadius.circular(chip);
  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get heroRadius => BorderRadius.circular(hero);
  static BorderRadius get capsuleRadius => BorderRadius.circular(capsule);
}
