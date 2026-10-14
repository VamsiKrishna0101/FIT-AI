import 'workout_exercise_models.dart';

class TrainingDay {
  final Map<String, dynamic> json;
  TrainingDay(this.json);

  String get date => json['date'] as String;
  String get name => json['name'] as String? ?? 'Workout';
  bool get restDay => json['restDay'] == true;
  Map<String, dynamic>? get session =>
      (json['session'] as Map?)?.cast<String, dynamic>();
  bool get started => session != null;
  bool get finished => session?['status'] == 'COMPLETED';
  List<Map<String, dynamic>> get rawItems => (json['items'] as List? ?? [])
      .map((row) => (row as Map).cast<String, dynamic>())
      .toList();
  List<TodayPlanItemModel> get items =>
      rawItems.map(TodayPlanItemModel.fromJson).toList();
  List<Map<String, dynamic>> logs(String itemId) =>
      (rawItems.firstWhere((row) => row['id'] == itemId)['setLogs'] as List? ??
              [])
          .map((row) => (row as Map).cast<String, dynamic>())
          .toList();
  List<Map<String, dynamic>> get week => (json['week'] as List? ?? [])
      .map((row) => (row as Map).cast<String, dynamic>())
      .toList();
  List<Map<String, dynamic>> get routines => (json['routines'] as List? ?? [])
      .map((row) => (row as Map).cast<String, dynamic>())
      .toList();
  int get loggedSets => (json['summary']?['sets'] as num?)?.toInt() ?? 0;
  int get durationSeconds =>
      (session?['durationSeconds'] as num?)?.toInt() ?? 0;
  int get skipped => (json['summary']?['skipped'] as num?)?.toInt() ?? 0;
  bool get pendingSync => (json['pendingSync'] as num? ?? 0) > 0;
  bool get syncBlocked => json['syncBlocked'] == true;
  bool get allResolved =>
      items.isNotEmpty && items.every((item) => !item.isPending);
  double get volume => (json['summary']?['volume'] as num?)?.toDouble() ?? 0;
  int get estimatedMinutes => items.isEmpty
      ? 0
      : (items.fold<int>(
                  0,
                  (seconds, item) =>
                      seconds +
                      item.targetSets * 45 +
                      (item.targetSets - 1) * item.restSeconds +
                      60) /
              60)
          .ceil();

  static Map<String, dynamic> targets(TodayPlanItemModel item) => {
        'workoutId': item.exercise.id,
        'targetSets': item.targetSets,
        'targetReps': item.targetReps,
        'targetWeight': item.targetWeight,
        'restSeconds': item.restSeconds,
        if (item.setTargets != null) 'setTargets': item.setTargets,
      };
}
