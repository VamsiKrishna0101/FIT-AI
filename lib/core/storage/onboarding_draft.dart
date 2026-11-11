import 'local_cache.dart';

// MARK: - Onboarding Draft Model (Persisted locally until user registers)
class OnboardingDraft {
  String languageCode;
  String countryCode;
  String? workingToward;
  String? name;
  String? experienceLevel;
  String?
      daysPerWeek; // Matches Prisma DaysPerWeek: DAYS_2, DAYS_3, DAYS_4, DAYS_5, DAYS_6_PLUS
  String?
      workoutDuration; // Matches Prisma WorkoutDuration: MIN_20, MIN_30, MIN_45, MIN_60_PLUS
  String?
      trainingLocation; // Matches Prisma TrainingLocation: GYM, HOME, OUTDOORS, MIX
  String? preferredTime;
  String? gender;
  double? weightKg;
  double? targetWeightKg;
  double? heightCm;
  int? age;
  int completedStep;

  String? get goal => workingToward;
  set goal(String? value) => workingToward = value;

  /// Stable, language-independent equipment IDs selected during onboarding.
  List<String> equipmentIds;

  // Recovery & Daily Lifestyle
  String? activityLevel; // Matches Prisma ActivityLevel: LOW, MODERATE, HIGH
  String?
      sleepDuration; // Matches Prisma SleepDuration: LESS_THAN_6_HOURS, HOURS_6_TO_7, HOURS_7_TO_8, HOURS_8_PLUS

  // Nutrition & Budget
  String? eatingStyle; // Matches Prisma EatingStyle, including NON_VEGETARIAN
  String? customEatingStyle; // e.g. "Keto", "Pescatarian", "Halal"
  String?
      weeklyFoodBudget; // Matches Prisma WeeklyFoodBudget: BUDGET_50, BUDGET_75, BUDGET_100, BUDGET_150, BUDGET_200_PLUS
  double? customWeeklyFoodBudget; // e.g. 125.0

  // Limitations & Injury Prevention
  List<String>
      limitations; // Matches Prisma BodyLimitation[]: NONE, SHOULDER, KNEE, BACK, WRIST, HIP, OTHER
  String?
      customLimitations; // e.g. "L4-L5 disc herniation, avoid heavy spinal loading"
  List<String> trainingDays;
  String trainingSplit;
  Map<String, List<String>> customTrainingSplit;
  List<String> focusMuscles;
  List<String> foodAllergies;
  List<String> dislikedFoods;
  List<String> stapleProteins;
  List<String> stapleCarbs;
  List<String> dietaryExclusions;
  String? foodBudgetCurrency;

  OnboardingDraft({
    this.languageCode = 'en',
    this.countryCode = 'ZZ',
    this.workingToward,
    String? goal,
    this.name,
    this.experienceLevel,
    this.daysPerWeek,
    this.workoutDuration,
    this.trainingLocation,
    this.preferredTime,
    this.gender,
    this.weightKg,
    this.targetWeightKg,
    this.heightCm,
    this.age,
    this.equipmentIds = const [],
    this.activityLevel,
    this.sleepDuration,
    this.eatingStyle,
    this.customEatingStyle,
    this.weeklyFoodBudget,
    this.customWeeklyFoodBudget,
    this.limitations = const ['NONE'],
    this.customLimitations,
    this.trainingDays = const [],
    this.trainingSplit = 'AUTO',
    this.customTrainingSplit = const {},
    this.focusMuscles = const [],
    this.foodAllergies = const [],
    this.dislikedFoods = const [],
    this.stapleProteins = const [],
    this.stapleCarbs = const [],
    this.dietaryExclusions = const [],
    this.foodBudgetCurrency,
    this.completedStep = 1,
  }) {
    if (workingToward == null && goal != null) {
      workingToward = goal;
    }
  }

  Map<String, dynamic> toJson() => {
        'languageCode': languageCode,
        'countryCode': countryCode,
        'workingToward': workingToward,
        'goal': workingToward,
        'name': name,
        'experienceLevel': experienceLevel,
        'daysPerWeek': daysPerWeek,
        'workoutDuration': workoutDuration,
        'trainingLocation': trainingLocation,
        'preferredTime': preferredTime,
        'gender': gender,
        'weightKg': weightKg,
        'targetWeightKg': targetWeightKg,
        'heightCm': heightCm,
        'age': age,
        'equipmentIds': equipmentIds,
        'activityLevel': activityLevel,
        'sleepDuration': sleepDuration,
        'eatingStyle': eatingStyle,
        'customEatingStyle': customEatingStyle,
        'weeklyFoodBudget': weeklyFoodBudget,
        'customWeeklyFoodBudget': customWeeklyFoodBudget,
        'limitations': limitations,
        'customLimitations': customLimitations,
        'trainingDays': trainingDays,
        'trainingSplit': trainingSplit,
        'customTrainingSplit': customTrainingSplit,
        'focusMuscles': focusMuscles,
        'foodAllergies': foodAllergies,
        'dislikedFoods': dislikedFoods,
        'stapleProteins': stapleProteins,
        'stapleCarbs': stapleCarbs,
        'dietaryExclusions': dietaryExclusions,
        'foodBudgetCurrency': foodBudgetCurrency,
        'completedStep': completedStep,
      };

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) {
    String? parseDaysPerWeek(dynamic val) {
      if (val == null) return null;
      if (val is String) return val;
      if (val is int) {
        switch (val) {
          case 2:
            return 'DAYS_2';
          case 3:
            return 'DAYS_3';
          case 4:
            return 'DAYS_4';
          case 5:
            return 'DAYS_5';
          case 6:
            return 'DAYS_6_PLUS';
          default:
            return 'DAYS_4';
        }
      }
      return null;
    }

    return OnboardingDraft(
      languageCode: json['languageCode'] as String? ?? 'en',
      countryCode: json['countryCode'] as String? ?? 'ZZ',
      workingToward: (json['workingToward'] ?? json['goal']) as String?,
      name: json['name'] as String?,
      experienceLevel: json['experienceLevel'] as String?,
      daysPerWeek: parseDaysPerWeek(json['daysPerWeek']),
      workoutDuration: json['workoutDuration'] as String?,
      trainingLocation: json['trainingLocation'] as String?,
      preferredTime: json['preferredTime'] as String?,
      gender: json['gender'] as String?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      age: json['age'] as int?,
      equipmentIds: (json['equipmentIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      activityLevel: json['activityLevel'] as String?,
      sleepDuration: json['sleepDuration'] as String?,
      eatingStyle: json['eatingStyle'] as String?,
      customEatingStyle: json['customEatingStyle'] as String?,
      weeklyFoodBudget: json['weeklyFoodBudget'] as String?,
      customWeeklyFoodBudget:
          (json['customWeeklyFoodBudget'] as num?)?.toDouble(),
      limitations: (json['limitations'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const ['NONE'],
      customLimitations: json['customLimitations'] as String?,
      trainingDays:
          (json['trainingDays'] as List? ?? []).whereType<String>().toList(),
      trainingSplit: json['trainingSplit'] as String? ?? 'AUTO',
      customTrainingSplit: {
        for (final entry in (json['customTrainingSplit'] as Map? ?? {}).entries)
          if (entry.value is List)
            entry.key.toString():
                (entry.value as List).whereType<String>().toList(),
      },
      focusMuscles:
          (json['focusMuscles'] as List? ?? []).whereType<String>().toList(),
      foodAllergies:
          (json['foodAllergies'] as List? ?? []).whereType<String>().toList(),
      dislikedFoods:
          (json['dislikedFoods'] as List? ?? []).whereType<String>().toList(),
      stapleProteins: (json['stapleProteins'] as List? ?? [])
          .whereType<String>()
          .toList(),
      stapleCarbs:
          (json['stapleCarbs'] as List? ?? []).whereType<String>().toList(),
      dietaryExclusions: (json['dietaryExclusions'] as List? ?? [])
          .whereType<String>()
          .toList(),
      foodBudgetCurrency: json['foodBudgetCurrency'] as String?,
      completedStep: json['completedStep'] as int? ?? 1,
    );
  }

  // Persistence helpers
  Map<String, dynamic> personalizationPayload() => {
        'countryCode': countryCode,
        'preferredTime': preferredTime ?? 'ANY',
        'trainingDays': trainingDays,
        'trainingSplit': trainingSplit,
        'customTrainingSplit': {
          for (final day in trainingDays)
            if (customTrainingSplit[day]?.isNotEmpty == true)
              day: customTrainingSplit[day],
        },
        'focusMuscles': focusMuscles,
        'customLimitations': customLimitations?.trim().isEmpty == true
            ? null
            : customLimitations,
        'foodAllergies': [
          ...foodAllergies,
          ...dietaryExclusions,
        ],
        'dislikedFoods': dislikedFoods,
        'stapleProteins': stapleProteins,
        'stapleCarbs': stapleCarbs,
        'dietaryExclusions': dietaryExclusions,
      };

  static Future<OnboardingDraft> load() async {
    final json = await LocalCache.shared.getJson(LocalCache.keyOnboardingDraft);
    if (json == null) return OnboardingDraft();
    return OnboardingDraft.fromJson(json);
  }

  Future<void> save() async {
    await LocalCache.shared.saveJson(LocalCache.keyOnboardingDraft, toJson());
  }

  static Future<void> clear() async {
    await LocalCache.shared.remove(LocalCache.keyOnboardingDraft);
  }
}
