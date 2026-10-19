class TrainingMapData {
  final String date, weekStart, gender;
  final List<MuscleRegion> regions;
  final Map<String, dynamic> summary;
  final List<String> unmapped;
  TrainingMapData.fromJson(Map<String, dynamic> json)
      : date = json['date'] as String,
        weekStart = json['weekStart'] as String,
        gender = json['gender'] as String? ?? 'OTHER',
        regions = (json['regions'] as List)
            .map((e) =>
                MuscleRegion.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        summary = Map<String, dynamic>.from(json['summary'] as Map),
        unmapped = (json['unmappedExercises'] as List? ?? [])
            .whereType<String>()
            .toList();
}

class MuscleRegion {
  final String id, label, status, insight;
  final int completedSets, targetSets, dueSets, assistingSets, previousWeekSets;
  final String? lastTrained, lastExposure, trendExercise;
  final int? daysSinceTrained, soreness;
  final bool isFocus, hasLimitation;
  final List<Map<String, dynamic>> sessions, trend, nextExercises;
  final Map<String, dynamic> strength;
  int get strengthTier => (strength["tier"] as num? ?? 0).toInt().clamp(0, 5);
  String get strengthTitle => strength["title"] as String? ?? "Not ranked yet";
  List<Map<String, dynamic>> get rankedExercises =>
      _maps(strength["exercises"]);
  MuscleRegion.fromJson(Map<String, dynamic> j)
      : strength = Map<String, dynamic>.from(j['strength'] as Map? ?? const {}),
        id = j['id'] as String,
        label = j['label'] as String,
        status = j['status'] as String,
        insight = j['insight'] as String,
        completedSets = (j['completedSets'] as num).toInt(),
        targetSets = (j['targetSets'] as num).toInt(),
        dueSets = (j['dueSets'] as num).toInt(),
        assistingSets = (j['assistingSets'] as num).toInt(),
        previousWeekSets = (j['previousWeekSets'] as num).toInt(),
        lastTrained = j['lastTrained'] as String?,
        lastExposure = j['lastExposure'] as String?,
        trendExercise = j['trendExercise'] as String?,
        daysSinceTrained = (j['daysSinceTrained'] as num?)?.toInt(),
        soreness = (j['soreness'] as num?)?.toInt(),
        isFocus = j['isFocus'] == true,
        hasLimitation = j['hasLimitation'] == true,
        sessions = _maps(j['sessions']),
        trend = _maps(j['trend']),
        nextExercises = _maps(j['nextExercises']);
  static List<Map<String, dynamic>> _maps(dynamic value) =>
      (value as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
}
