import 'package:setcraft/features/body_scan/models/body_map_models.dart';

BodyMapData emptyBodyMap([DateTime? date]) {
  final week = bodyMapWeek(date ?? DateTime.now());
  String day(int offset) => DateTime(week.year, week.month, week.day + offset)
      .toIso8601String()
      .substring(0, 10);
  return BodyMapData.fromJson({
    'date': day(0),
    'weekStart': day(0),
    'weekEnd': day(6),
    'gender': 'MALE',
    'planId': null,
    'status': 'none',
    'regions': [],
    'workouts': [],
    'summary': {'plannedSets': 0, 'loggedSets': 0},
  });
}
