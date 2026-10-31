import 'planned_physique_models.dart';

class BodyMapData {
  final String date, weekStart, weekEnd, gender;
  final String? planId;
  final List<BodyMapRegion> regions;
  final List<PlannedPhysiqueDay> workouts;
  final int plannedSets, loggedSets, sessions, trainedMuscles;
  BodyMapData.fromJson(Map<String, dynamic> json)
      : date = json['date'] as String,
        weekStart = json['weekStart'] as String,
        weekEnd = json['weekEnd'] as String,
        gender = json['gender'] as String? ?? 'OTHER',
        planId = json['planId'] as String?,
        regions = (json['regions'] as List)
            .map((r) =>
                BodyMapRegion.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
        workouts = (json['workouts'] as List? ?? [])
            .whereType<Map>()
            .map(PlannedPhysiqueDay.fromJson)
            .toList(),
        plannedSets =
            ((json['summary'] as Map?)?['plannedSets'] as num?)?.toInt() ?? 0,
        sessions =
            ((json['summary'] as Map?)?['sessions'] as num?)?.toInt() ?? 0,
        trainedMuscles =
            ((json['summary'] as Map?)?['trainedMuscles'] as num?)?.toInt() ??
                0,
        loggedSets =
            ((json['summary'] as Map?)?['loggedSets'] as num?)?.toInt() ?? 0;
  bool get hasPlan => planId != null;
}

class BodyMapRegion {
  final String id, status;
  final String? lastTrained;
  final int plannedSets, completedSets, assistingSets;
  final Map<String, dynamic> strength;
  final List<Map<String, dynamic>> sessions, trend, loggedExercises;
  final String? trendExercise;
  BodyMapRegion.fromJson(Map<String, dynamic> json)
      : strength = Map<String, dynamic>.from(json['strength'] as Map? ?? {}),
        sessions = _maps(json['sessions']),
        trend = _maps(json['trend']),
        loggedExercises = _maps(json['loggedExercises']),
        trendExercise = json['trendExercise'] as String?,
        id = json['id'] as String,
        status = json['status'] as String? ?? 'none',
        lastTrained = json['lastTrained'] as String?,
        plannedSets = (json['plannedSets'] as num?)?.toInt() ?? 0,
        completedSets = (json['completedSets'] as num?)?.toInt() ?? 0,
        assistingSets = (json['assistingSets'] as num?)?.toInt() ?? 0;
  bool get isTrained => completedSets > 0 || assistingSets > 0;
  int get involvedSets => completedSets + assistingSets;
}

DateTime bodyMapWeek(DateTime date) =>
    DateTime(date.year, date.month, date.day - date.weekday + 1);

List<Map<String, dynamic>> _maps(dynamic value) => (value as List? ?? [])
    .whereType<Map>()
    .map((row) => Map<String, dynamic>.from(row))
    .toList();

enum BodyDateMode { day, days, range, all }

class BodyDateSelection {
  final BodyDateMode mode;
  final DateTime end;
  final DateTime? start;
  final List<DateTime> dates;
  BodyDateSelection(
      {required this.mode,
      required DateTime end,
      DateTime? start,
      List<DateTime> dates = const []})
      : end = DateTime(end.year, end.month, end.day),
        start =
            start == null ? null : DateTime(start.year, start.month, start.day),
        dates = List.unmodifiable(
            dates.map((d) => DateTime(d.year, d.month, d.day)));
  factory BodyDateSelection.thisWeek(DateTime today) => BodyDateSelection(
      mode: BodyDateMode.range, start: bodyMapWeek(today), end: today);
  Map<String, dynamic> get query => switch (mode) {
        BodyDateMode.all => {'all': 'true'},
        BodyDateMode.range => {'from': _key(start ?? end)},
        _ => {
            'dates': (dates.isEmpty ? [end] : dates).map(_key).join(',')
          },
      };
  static String _key(DateTime d) => d.toIso8601String().substring(0, 10);
}
