class PlannedPhysiqueData {
  final String status, date, gender;
  final String? planId, weekStart;
  final List<PlannedPhysiqueDay> workouts;
  PlannedPhysiqueData.fromJson(Map<String, dynamic> json)
      : status = json['status'] as String? ?? 'none',
        date = json['date'] as String? ?? '',
        gender = json['gender'] as String? ?? 'OTHER',
        planId = json['planId'] as String?,
        weekStart = json['weekStart'] as String?,
        workouts = (json['workouts'] as List? ?? [])
            .whereType<Map>()
            .map((day) => PlannedPhysiqueDay.fromJson(day))
            .toList();
  bool get hasPlan => planId != null && ['active', 'upcoming'].contains(status);
}

class PlannedPhysiqueDay {
  final String date, name, status;
  final bool restDay;
  final int? estimatedMinutes;
  final List<PlannedPhysiqueExercise> exercises;
  PlannedPhysiqueDay.fromJson(Map json)
      : date = json['date'] as String,
        name = json['name'] as String? ?? 'Workout',
        status = json['status'] as String? ?? 'NOT_STARTED',
        restDay = json['restDay'] == true,
        estimatedMinutes = (json['estimatedMinutes'] as num?)?.toInt(),
        exercises = (json['exercises'] as List? ?? [])
            .whereType<Map>()
            .map((e) => PlannedPhysiqueExercise.fromJson(e))
            .toList();
}

class PlannedPhysiqueExercise {
  final String itemId, exerciseId, name, targetReps;
  final String? reason, progression;
  final int sets;
  final double? weightKg;
  final List<String> primary, secondary;
  PlannedPhysiqueExercise.fromJson(Map json)
      : itemId = json['itemId'] as String,
        exerciseId = json['exerciseId'] as String,
        name = json['name'] as String,
        targetReps = json['targetReps'] as String? ?? '',
        sets = (json['sets'] as num?)?.toInt() ?? 0,
        weightKg = (json['weightKg'] as num?)?.toDouble(),
        reason = json['reason'] as String?,
        progression = json['progression'] as String?,
        primary = (json['primary'] as List? ?? []).whereType<String>().toList(),
        secondary =
            (json['secondary'] as List? ?? []).whereType<String>().toList();
}
