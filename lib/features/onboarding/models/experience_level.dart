import 'package:flutter/material.dart';
import '../../../core/theme/ds_colors.dart';

// MARK: - Prisma Experience Enum Alignment for Onboarding Screen 02/03
enum ExperienceLevel {
  beginner('BEGINNER', '🌱'),
  intermediate('INTERMEDIATE', '🏋️'),
  advanced('ADVANCED', '🔥');

  final String backendValue;
  final String emoji;

  const ExperienceLevel(this.backendValue, this.emoji);

  Color get accentColor {
    switch (this) {
      case ExperienceLevel.beginner:
        return DSColors.accent; // Electric Lime
      case ExperienceLevel.intermediate:
        return const Color(0xFF4DD8FF); // Cyan
      case ExperienceLevel.advanced:
        return const Color(0xFFFF5A4E); // Coral
    }
  }

  Color get checkmarkColor {
    switch (this) {
      case ExperienceLevel.beginner:
        return DSColors.onAccent;
      case ExperienceLevel.intermediate:
      case ExperienceLevel.advanced:
        return Colors.white;
    }
  }

  static ExperienceLevel fromBackend(String? value) {
    if (value == null) return ExperienceLevel.intermediate;
    return ExperienceLevel.values.firstWhere(
      (e) => e.backendValue == value,
      orElse: () => ExperienceLevel.intermediate,
    );
  }
}
