import 'package:flutter_test/flutter_test.dart';
import 'package:fitai_mobile/core/localization/app_language.dart';
import 'package:fitai_mobile/core/storage/onboarding_draft.dart';
import 'package:fitai_mobile/features/onboarding/models/training_schedule_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingDraft Schedule & Location Serialization', () {
    test('serializes and deserializes correctly', () {
      final draft = OnboardingDraft(
        daysPerWeek: 'DAYS_4',
        workoutDuration: 'MIN_45',
        trainingLocation: 'GYM',
        completedStep: 4,
      );

      final json = draft.toJson();
      expect(json['daysPerWeek'], 'DAYS_4');
      expect(json['workoutDuration'], 'MIN_45');
      expect(json['trainingLocation'], 'GYM');
      expect(json['completedStep'], 4);

      final restored = OnboardingDraft.fromJson(json);
      expect(restored.daysPerWeek, 'DAYS_4');
      expect(restored.workoutDuration, 'MIN_45');
      expect(restored.trainingLocation, 'GYM');
      expect(restored.completedStep, 4);
    });

    test('backward compatibility converts legacy int daysPerWeek to enum string', () {
      final legacyJson = {
        'daysPerWeek': 4,
        'workoutDuration': 'MIN_45',
        'trainingLocation': 'HOME',
      };

      final restored = OnboardingDraft.fromJson(legacyJson);
      expect(restored.daysPerWeek, 'DAYS_4');
      expect(restored.workoutDuration, 'MIN_45');
      expect(restored.trainingLocation, 'HOME');
    });
  });

  group('Training Schedule Models mapping', () {
    test('DaysPerWeekOption maps correctly', () {
      expect(DaysPerWeekOption.fromBackend('DAYS_2'), DaysPerWeekOption.days2);
      expect(DaysPerWeekOption.fromBackend('DAYS_3'), DaysPerWeekOption.days3);
      expect(DaysPerWeekOption.fromBackend('DAYS_4'), DaysPerWeekOption.days4);
      expect(DaysPerWeekOption.fromBackend('DAYS_5'), DaysPerWeekOption.days5);
      expect(DaysPerWeekOption.fromBackend('DAYS_6_PLUS'), DaysPerWeekOption.days6Plus);
      expect(DaysPerWeekOption.fromBackend(null), isNull);
    });

    test('WorkoutDurationOption maps correctly', () {
      expect(WorkoutDurationOption.fromBackend('MIN_20'), WorkoutDurationOption.min20);
      expect(WorkoutDurationOption.fromBackend('MIN_30'), WorkoutDurationOption.min30);
      expect(WorkoutDurationOption.fromBackend('MIN_45'), WorkoutDurationOption.min45);
      expect(WorkoutDurationOption.fromBackend('MIN_60_PLUS'), WorkoutDurationOption.min60Plus);
      expect(WorkoutDurationOption.fromBackend(null), WorkoutDurationOption.min45);
    });

    test('TrainingLocationOption maps correctly', () {
      expect(TrainingLocationOption.fromBackend('GYM'), TrainingLocationOption.gym);
      expect(TrainingLocationOption.fromBackend('HOME'), TrainingLocationOption.home);
      expect(TrainingLocationOption.fromBackend('OUTDOORS'), TrainingLocationOption.outdoors);
      expect(TrainingLocationOption.fromBackend('MIX'), TrainingLocationOption.mix);
      expect(TrainingLocationOption.fromBackend(null), TrainingLocationOption.gym);
    });
  });

  group('Multilingual AI Summary calculations', () {
    test('renders rhythm summary accurately', () {
      final summary = AppLanguage.uk.scheduleRhythmSummary(4, 45, 'Gym');
      expect(summary, contains('4 days × 45 min = 3.0 hrs/wk'));
      expect(summary, contains('Optimized for Gym'));
    });
  });
}
