import 'package:flutter/material.dart';

// MARK: - Screen 04: Days Per Week Enum (Matches Prisma DaysPerWeek)
enum DaysPerWeekOption {
  days2('DAYS_2', 2),
  days3('DAYS_3', 3),
  days4('DAYS_4', 4),
  days5('DAYS_5', 5),
  days6Plus('DAYS_6_PLUS', 6);

  final String backendValue;
  final int daysCount;
  const DaysPerWeekOption(this.backendValue, this.daysCount);

  static DaysPerWeekOption? fromBackend(String? value) {
    if (value == null) return null;
    for (final option in DaysPerWeekOption.values) {
      if (option.backendValue == value) return option;
    }
    return null;
  }
}

// MARK: - Screen 04: Workout Duration Enum (Matches Prisma WorkoutDuration)
enum WorkoutDurationOption {
  min20('MIN_20', 20),
  min30('MIN_30', 30),
  min45('MIN_45', 45),
  min60Plus('MIN_60_PLUS', 60);

  final String backendValue;
  final int minutes;
  const WorkoutDurationOption(this.backendValue, this.minutes);

  static WorkoutDurationOption fromBackend(String? value) {
    if (value == null) return WorkoutDurationOption.min45;
    return WorkoutDurationOption.values.firstWhere(
      (e) => e.backendValue == value,
      orElse: () => WorkoutDurationOption.min45,
    );
  }
}

// MARK: - Screen 05: Training Location Enum (Matches Prisma TrainingLocation)
enum TrainingLocationOption {
  gym(
    'GYM',
    '🏋️',
    'Full Gym',
    Color(0xFFC6FF3D), // Electric Lime
  ),
  home(
    'HOME',
    '🏠',
    'Home Setup',
    Color(0xFF4DD8FF), // Ice Cyan
  ),
  outdoors(
    'OUTDOORS',
    '🌳',
    'Outdoors',
    Color(0xFF7CFF6B), // Emerald Energy
  ),
  mix(
    'MIX',
    '🔄',
    'Hybrid Mix',
    Color(0xFF8B7BFF), // Violet Pulse
  );

  final String backendValue;
  final String emoji;
  final String defaultTitle;
  final Color accentColor;

  const TrainingLocationOption(
    this.backendValue,
    this.emoji,
    this.defaultTitle,
    this.accentColor,
  );

  static TrainingLocationOption fromBackend(String? value) {
    if (value == null) return TrainingLocationOption.gym;
    return TrainingLocationOption.values.firstWhere(
      (e) => e.backendValue == value,
      orElse: () => TrainingLocationOption.gym,
    );
  }
}
