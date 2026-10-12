import 'package:flutter/material.dart';

/// Shared type scale based on Apple's compact, high-legibility system style.
/// The system font stays platform-native: SF on Apple platforms, Roboto on
/// Android. This avoids shipping or downloading font files while keeping the
/// same sizes, weights, and tracking throughout the app.
class DSTypography {
  static const String? family = null;

  static const TextStyle onboardingTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.72,
    height: 1.12,
  );

  static const TextStyle onboardingSubtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.12,
    height: 1.42,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.28,
    height: 1.3,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
    height: 1.12,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle controlLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle eyebrow = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    height: 1.25,
  );

  const DSTypography._();
}
