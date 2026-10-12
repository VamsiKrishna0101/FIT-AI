// MARK: - FitAI Home Dashboard Models (matches GET /api/home)

class HomeData {
  final String wearableUsage;
  final String? calendarDate;
  final Map<String, dynamic>? sleepLog;
  final HomeUser user;
  final HomeReadiness? readiness;
  final HomeHealthMetrics? healthMetrics;
  final HomeTodayWorkout? todayWorkout;
  final HomeNutrition nutrition;
  final List<WeekDay> weeklyStreak;

  const HomeData({
    this.wearableUsage = 'UNKNOWN',
    this.calendarDate,
    this.sleepLog,
    required this.user,
    this.readiness,
    this.healthMetrics,
    this.todayWorkout,
    required this.nutrition,
    required this.weeklyStreak,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      wearableUsage: json['wearableUsage'] as String? ?? 'UNKNOWN',
      calendarDate: json['calendarDate'] as String?,
      sleepLog: (json['sleepLog'] as Map?)?.cast<String, dynamic>(),
      healthMetrics: json['healthMetrics'] is Map
          ? HomeHealthMetrics.fromJson(
              Map<String, dynamic>.from(json['healthMetrics'] as Map))
          : null,
      user: HomeUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      readiness: json['readiness'] != null &&
              !RegExp('sample|preview|demo', caseSensitive: false)
                  .hasMatch(json['readiness']['source']?.toString() ?? '')
          ? HomeReadiness.fromJson(json['readiness'] as Map<String, dynamic>)
          : null,
      todayWorkout: json['todayWorkout'] != null
          ? HomeTodayWorkout.fromJson(
              json['todayWorkout'] as Map<String, dynamic>)
          : null,
      nutrition: HomeNutrition.fromJson(
          json['nutrition'] as Map<String, dynamic>? ?? {}),
      weeklyStreak: (json['weeklyStreak'] as List<dynamic>? ?? [])
          .map((e) => WeekDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'wearableUsage': wearableUsage,
        'calendarDate': calendarDate,
        'sleepLog': sleepLog,
        'user': user.toJson(),
        'readiness': readiness?.toJson(),
        'healthMetrics': healthMetrics?.toJson(),
        'todayWorkout': todayWorkout?.toJson(),
        'nutrition': nutrition.toJson(),
        'weeklyStreak': weeklyStreak.map((e) => e.toJson()).toList(),
      };
}

class HomeHealthMetrics {
  final String date, source;
  final String? syncedAt, hrvMethod;
  final int? steps;
  final double? activeCalories, sleepMinutes, restingHR, hrv;
  const HomeHealthMetrics(
      {required this.date,
      required this.source,
      this.syncedAt,
      this.steps,
      this.activeCalories,
      this.sleepMinutes,
      this.restingHR,
      this.hrv,
      this.hrvMethod});
  factory HomeHealthMetrics.fromJson(Map<String, dynamic> j) =>
      HomeHealthMetrics(
          date: j['date'] as String,
          source: j['source'] as String,
          syncedAt: j['syncedAt'] as String?,
          steps: (j['steps'] as num?)?.toInt(),
          activeCalories: (j['activeCalories'] as num?)?.toDouble(),
          sleepMinutes: (j['sleepMinutes'] as num?)?.toDouble(),
          restingHR: (j['restingHR'] as num?)?.toDouble(),
          hrv: (j['hrv'] as num?)?.toDouble(),
          hrvMethod: j['hrvMethod'] as String?);
  Map<String, dynamic> toJson() => {
        'date': date,
        'source': source,
        'syncedAt': syncedAt,
        'steps': steps,
        'activeCalories': activeCalories,
        'sleepMinutes': sleepMinutes,
        'restingHR': restingHR,
        'hrv': hrv,
        'hrvMethod': hrvMethod
      };
}

class HomeUser {
  final String name;
  final String? email;
  final int streakDays;

  const HomeUser({
    required this.name,
    this.email,
    required this.streakDays,
  });

  factory HomeUser.fromJson(Map<String, dynamic> json) => HomeUser(
        name: json['name'] as String? ?? '',
        email: json['email'] as String?,
        streakDays: json['streakDays'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'streakDays': streakDays,
      };
}

class HomeReadiness {
  final double score;
  final String label;
  final String aiTarget;
  final String source;
  final String? date;
  final int hrvMs;
  final String? hrvMethod;
  final int sleepMinutes;
  final int sleepEfficiency;
  final int restingHrBpm;
  final int steps;
  final int activeCalories;

  const HomeReadiness({
    required this.score,
    required this.label,
    required this.aiTarget,
    this.source = 'manual',
    this.date,
    this.hrvMs = 0,
    this.hrvMethod,
    this.sleepMinutes = 0,
    this.sleepEfficiency = 0,
    this.restingHrBpm = 0,
    this.steps = 0,
    this.activeCalories = 0,
  });

  factory HomeReadiness.fromJson(Map<String, dynamic> json) => HomeReadiness(
        score: (json['score'] as num?)?.toDouble() ?? 0,
        label: json['label'] as String? ?? '',
        aiTarget: json['aiTarget'] as String? ?? '',
        source: json['source'] as String? ?? 'manual',
        date: json['date'] as String?,
        hrvMs: (json['hrvMs'] as num?)?.toInt() ?? 0,
        hrvMethod: json['hrvMethod'] as String?,
        sleepMinutes: (json['sleepMinutes'] as num?)?.toInt() ?? 0,
        sleepEfficiency: (json['sleepEfficiency'] as num?)?.toInt() ?? 0,
        restingHrBpm: (json['restingHrBpm'] as num?)?.toInt() ?? 0,
        steps: (json['steps'] as num?)?.toInt() ?? 0,
        activeCalories: (json['activeCalories'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'score': score,
        'label': label,
        'aiTarget': aiTarget,
        'source': source,
        'date': date,
        'hrvMs': hrvMs,
        'hrvMethod': hrvMethod,
        'sleepMinutes': sleepMinutes,
        'sleepEfficiency': sleepEfficiency,
        'restingHrBpm': restingHrBpm,
        'steps': steps,
        'activeCalories': activeCalories,
      };
}

class HomeTodayWorkout {
  final String userWorkoutId;
  final String weekLabel;
  final String workoutTitle;
  final String? sessionTitle;
  final String category;
  final int exerciseCount;
  final int durationMinutes;
  final String status;
  final String? aiNote;

  const HomeTodayWorkout({
    required this.userWorkoutId,
    required this.weekLabel,
    required this.workoutTitle,
    this.sessionTitle,
    required this.category,
    required this.exerciseCount,
    required this.durationMinutes,
    required this.status,
    this.aiNote,
  });

  factory HomeTodayWorkout.fromJson(Map<String, dynamic> json) =>
      HomeTodayWorkout(
        userWorkoutId: json['userWorkoutId'] as String? ?? '',
        weekLabel: json['weekLabel'] as String? ?? '',
        workoutTitle: json['workoutTitle'] as String? ?? '',
        sessionTitle: json['sessionTitle'] as String?,
        category: json['category'] as String? ?? '',
        exerciseCount: json['exerciseCount'] as int? ?? 0,
        durationMinutes: json['durationMinutes'] as int? ?? 0,
        status: json['status'] as String? ?? '',
        aiNote: json['aiNote'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'userWorkoutId': userWorkoutId,
        'weekLabel': weekLabel,
        'workoutTitle': workoutTitle,
        'sessionTitle': sessionTitle,
        'category': category,
        'exerciseCount': exerciseCount,
        'durationMinutes': durationMinutes,
        'status': status,
        'aiNote': aiNote,
      };
}

class MacroTarget {
  final int consumed;
  final int target;

  const MacroTarget({
    required this.consumed,
    required this.target,
  });

  factory MacroTarget.fromJson(Map<String, dynamic> json) => MacroTarget(
        consumed: (json['consumed'] as num?)?.toInt() ?? 0,
        target: (json['target'] as num?)?.toInt() ?? 0,
      );

  double get progress => target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
        'consumed': consumed,
        'target': target,
      };
}

class HomeNutrition {
  final MacroTarget calories;
  final MacroTarget protein;
  final MacroTarget carbs;
  final MacroTarget fat;
  final MacroTarget water;

  const HomeNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.water,
  });

  factory HomeNutrition.fromJson(Map<String, dynamic> json) => HomeNutrition(
        calories: MacroTarget.fromJson(
            json['calories'] as Map<String, dynamic>? ?? {}),
        protein: MacroTarget.fromJson(
            json['protein'] as Map<String, dynamic>? ?? {}),
        carbs:
            MacroTarget.fromJson(json['carbs'] as Map<String, dynamic>? ?? {}),
        fat: MacroTarget.fromJson(json['fat'] as Map<String, dynamic>? ?? {}),
        water: MacroTarget.fromJson(json['water'] as Map<String, dynamic>? ??
            {'consumed': 0, 'target': 0}),
      );

  Map<String, dynamic> toJson() => {
        'calories': calories.toJson(),
        'protein': protein.toJson(),
        'carbs': carbs.toJson(),
        'fat': fat.toJson(),
        'water': water.toJson(),
      };
}

class WeekDay {
  final String day;
  final int? dateNum;
  final String status;
  final bool isToday;

  const WeekDay({
    required this.day,
    this.dateNum,
    required this.status,
    this.isToday = false,
  });

  factory WeekDay.fromJson(Map<String, dynamic> json) => WeekDay(
        day: json['day'] as String? ?? 'MON',
        dateNum: json['dateNum'] as int?,
        status: json['status'] as String? ?? 'NOT_STARTED',
        isToday: json['isToday'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        'dateNum': dateNum,
        'status': status,
        'isToday': isToday,
      };
}
