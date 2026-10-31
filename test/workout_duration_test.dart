import 'package:flutter_test/flutter_test.dart';
import 'package:setcraft/features/train/models/training_session.dart';
import 'package:setcraft/features/train/models/workout_exercise_models.dart';

void main() {
  Map<String, dynamic> workout({int sets = 2, int rest = 60}) => {
        'id': 'plan',
        'date': '2026-10-27',
        'weekLabel': 'week',
        'warmup': {'durationMinutes': 5},
        'items': List.generate(
            4,
            (i) => {
                  'id': 'item-$i',
                  'targetSets': sets,
                  'targetReps': '10–12',
                  'restSeconds': rest,
                  'workout': {
                    'id': 'exercise-$i',
                    'name': 'Exercise',
                    'duration': 5
                  },
                }),
      };
  test('Home plan and live training use sets, reps, rest and warm-up', () {
    final json = workout();
    expect(TrainingDay(json).estimatedMinutes, 21);
    expect(TodayPlanModel.fromJson(json).estimatedDurationMinutes, 21);
    final longer = workout(sets: 3, rest: 90);
    expect(TrainingDay(longer).estimatedMinutes, 32);
    expect(TodayPlanModel.fromJson(longer).estimatedDurationMinutes, 32);
  });
  test('Offline target edits recalculate rather than keep a server estimate',
      () {
    final json = {...workout(), 'estimatedMinutes': 20};
    final day = TrainingDay(json);
    final edited = day.items
        .map((item) => item.copyWith(targetSets: 3, restSeconds: 90))
        .toList();
    expect(prescribedWorkoutMinutes(edited, 5), 32);
    expect(day.estimatedMinutes, 21);
  });
  test('Empty/rest days and single-set exercises do not invent rests', () {
    expect(TrainingDay({...workout(), 'restDay': true}).estimatedMinutes, 0);
    expect(TrainingDay({...workout(), 'items': []}).estimatedMinutes, 0);
    final item = TodayPlanItemModel.fromJson(
        {'targetSets': 1, 'targetReps': '10', 'restSeconds': 180});
    expect(prescribedWorkoutMinutes([item], 0), 2);
    expect(
        prescribedWorkoutMinutes([item.copyWith(targetReps: 'AMRAP')], 5), 0);
  });
}
