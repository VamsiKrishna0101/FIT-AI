import 'package:flutter/material.dart';

// MARK: - Screen 06: Activity Level Outside Workouts (Matches Prisma ActivityLevel)
enum ActivityLevelOption {
  low('LOW', '🪑', 'Low', 'Mostly sitting (desk work)', 1.375),
  moderate('MODERATE', '🚶', 'Moderate', 'On your feet / walking', 1.55,
      isRecommended: true),
  high('HIGH', '🏃', 'High', 'Active / physical work', 1.725);

  final String backendValue;
  final String emoji;
  final String defaultLabel;
  final String defaultSubtitle;
  final double tdeeMultiplier;
  final bool isRecommended;

  const ActivityLevelOption(
    this.backendValue,
    this.emoji,
    this.defaultLabel,
    this.defaultSubtitle,
    this.tdeeMultiplier, {
    this.isRecommended = false,
  });

  static ActivityLevelOption fromBackend(String? value) {
    if (value == null) return ActivityLevelOption.moderate;
    return ActivityLevelOption.values.firstWhere(
      (e) => e.backendValue == value,
      orElse: () => ActivityLevelOption.moderate,
    );
  }
}

// MARK: - Screen 06: Typical Nightly Sleep (Matches Prisma SleepDuration)
enum SleepDurationOption {
  lessThan6('LESS_THAN_6_HOURS', '< 6 hrs', 'Limited recovery window', 2),
  hours6To7('HOURS_6_TO_7', '6–7 hrs', 'Moderate recovery', 5),
  hours7To8('HOURS_7_TO_8', '7–8 hrs', 'Optimal restorative sleep', 8,
      isRecommended: true),
  hours8Plus('HOURS_8_PLUS', '8+ hrs', 'Maximum muscle repair', 10);

  final String backendValue;
  final String defaultLabel;
  final String defaultSubtitle;
  final int baselineReadinessScore;
  final bool isRecommended;

  const SleepDurationOption(
    this.backendValue,
    this.defaultLabel,
    this.defaultSubtitle,
    this.baselineReadinessScore, {
    this.isRecommended = false,
  });

  static SleepDurationOption fromBackend(String? value) {
    if (value == null) return SleepDurationOption.hours7To8;
    return SleepDurationOption.values.firstWhere(
      (e) => e.backendValue == value,
      orElse: () => SleepDurationOption.hours7To8,
    );
  }
}

// MARK: - Screen 07: Eating Style (Matches Prisma EatingStyle)
enum EatingStyleOption {
  noPreference(
    'NO_PREFERENCE',
    '🥩',
    'No Preference',
    'Balanced animal & plant proteins',
    Color(0xFFC6FF3D), // Electric Lime
  ),
  nonVegetarian(
    'NON_VEGETARIAN',
    '🍗',
    'Non-vegetarian',
    'Includes meat and fish',
    Color(0xFFFFB86B),
  ),
  vegetarian(
    'VEGETARIAN',
    '🥗',
    'Vegetarian',
    'Plant-based with dairy & eggs',
    Color(0xFF7CFF6B), // Emerald
  ),
  vegan(
    'VEGAN',
    '🥑',
    'Vegan',
    '100% whole plant foods',
    Color(0xFF4DD8FF), // Ice Cyan
  ),
  other(
    'OTHER',
    '🍽️',
    'Other',
    'Keto, Halal, Pescatarian, etc.',
    Color(0xFF8B7BFF), // Violet Pulse
    isCustom: true,
  );

  final String backendValue;
  final String emoji;
  final String defaultLabel;
  final String defaultSubtitle;
  final Color accentColor;
  final bool isCustom;

  const EatingStyleOption(
    this.backendValue,
    this.emoji,
    this.defaultLabel,
    this.defaultSubtitle,
    this.accentColor, {
    this.isCustom = false,
  });

  static EatingStyleOption fromBackend(String? value) {
    if (value == null) return EatingStyleOption.noPreference;
    return EatingStyleOption.values.firstWhere(
      (e) => e.backendValue == value,
      orElse: () => EatingStyleOption.noPreference,
    );
  }
}

// MARK: - Screen 07: Weekly Food Budget (Matches Prisma WeeklyFoodBudget)
enum WeeklyFoodBudgetOption {
  budget50('BUDGET_50', 50, '\$50', 'Budget staples & bulk buying'),
  budget75('BUDGET_75', 75, '\$75', 'Cost-effective whole foods'),
  budget100('BUDGET_100', 100, '\$100', 'Standard balanced nutrition',
      isRecommended: true),
  budget150('BUDGET_150', 150, '\$150', 'Premium protein variety'),
  budget200Plus(
      'BUDGET_200_PLUS', 200, '\$200+', 'Performance gourmet nutrition');

  final String backendValue;
  final int amount;
  final String defaultLabel;
  final String defaultSubtitle;
  final bool isRecommended;

  const WeeklyFoodBudgetOption(
    this.backendValue,
    this.amount,
    this.defaultLabel,
    this.defaultSubtitle, {
    this.isRecommended = false,
  });

  static WeeklyFoodBudgetOption fromBackend(String? value) {
    if (value == null) return WeeklyFoodBudgetOption.budget100;
    return WeeklyFoodBudgetOption.values.firstWhere(
      (e) => e.backendValue == value,
      orElse: () => WeeklyFoodBudgetOption.budget100,
    );
  }

  /// Maps custom numeric budget amount to the closest backend enum bracket
  static WeeklyFoodBudgetOption closestFromAmount(double amount) {
    if (amount <= 60) return WeeklyFoodBudgetOption.budget50;
    if (amount <= 85) return WeeklyFoodBudgetOption.budget75;
    if (amount <= 125) return WeeklyFoodBudgetOption.budget100;
    if (amount <= 175) return WeeklyFoodBudgetOption.budget150;
    return WeeklyFoodBudgetOption.budget200Plus;
  }
}

// MARK: - Screen 08: Body Limitation & Joint Care (Matches Prisma BodyLimitation)
enum BodyLimitationOption {
  none('NONE', '🛡️', 'None', 'Full mobility / no limitations',
      isExclusive: true),
  shoulder('SHOULDER', '🦾', 'Shoulder', 'Modify overhead pressing'),
  knee('KNEE', '🦵', 'Knee', 'Protect deep knee flexion'),
  back('BACK', '🦴', 'Lower Back', 'Avoid heavy spinal loading'),
  wrist('WRIST', '✋', 'Wrist', 'Neutral grips & cable cuffs'),
  hip('HIP', '🩻', 'Hip', 'Modify adductors & wide squats'),
  other('OTHER', '⚠️', 'Other', 'Describe injury or surgery', isCustom: true);

  final String backendValue;
  final String emoji;
  final String defaultLabel;
  final String defaultSubtitle;
  final bool isExclusive;
  final bool isCustom;

  const BodyLimitationOption(
    this.backendValue,
    this.emoji,
    this.defaultLabel,
    this.defaultSubtitle, {
    this.isExclusive = false,
    this.isCustom = false,
  });

  static BodyLimitationOption fromBackend(String? value) {
    if (value == null) return BodyLimitationOption.none;
    return BodyLimitationOption.values.firstWhere(
      (e) => e.backendValue == value,
      orElse: () => BodyLimitationOption.none,
    );
  }
}
