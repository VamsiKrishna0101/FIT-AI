import '../../../core/storage/onboarding_draft.dart';

const trainingStyleNames = {
  'AUTO': 'Recommend my weekly plan',
  'FULL_BODY': 'Train my whole body each session',
  'UPPER_LOWER': 'Alternate chest, back & arms with legs & core',
  'PUSH_PULL_LEGS': 'Chest & triceps, back & biceps, then legs',
  'MUSCLE_FOCUSED': 'Focus on different muscles each day',
  'CUSTOM': 'Choose muscles for each day',
};

class TrainingStylePreview {
  final OnboardingDraft draft;
  TrainingStylePreview(this.draft);
  static const days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY'
  ];
  int get count => draft.trainingDays.isNotEmpty
      ? draft.trainingDays.length
      : int.tryParse(
              draft.daysPerWeek?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ??
          3;
  int get minutes =>
      int.tryParse(
          draft.workoutDuration?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ??
      45;
  String get recommended {
    final limitedHome = draft.trainingLocation == 'HOME' &&
        !draft.equipmentIds
            .any((id) => !['bodyweight_only', 'yoga_mat'].contains(id));
    if (draft.experienceLevel == 'BEGINNER' &&
        count >= 3 &&
        minutes >= 30 &&
        !limitedHome) {
      return 'MUSCLE_FOCUSED';
    }
    if (count <= 3 || (limitedHome && minutes < 30)) return 'FULL_BODY';
    if (count == 6 &&
        draft.experienceLevel != null &&
        draft.experienceLevel != 'BEGINNER' &&
        minutes >= 40 &&
        ['BUILD_MUSCLE', 'GET_STRONGER'].contains(draft.workingToward)) {
      return 'PUSH_PULL_LEGS';
    }
    return 'UPPER_LOWER';
  }

  String get resolved =>
      draft.trainingSplit == 'AUTO' ? recommended : draft.trainingSplit;
  List<String> get selectedDays {
    if (draft.trainingDays.isNotEmpty) {
      return days.where(draft.trainingDays.contains).toList();
    }
    final indexes = <int, List<int>>{
      2: [0, 3],
      3: [0, 2, 4],
      4: [0, 1, 3, 4],
      5: [0, 1, 2, 4, 5],
      6: [0, 1, 2, 3, 4, 5]
    };
    return (indexes[count] ?? indexes[3]!).map((i) => days[i]).toList();
  }

  List<List<String>> get groups => List.generate(selectedDays.length, (i) {
        switch (resolved) {
          case 'CUSTOM':
            return draft.customTrainingSplit[selectedDays[i]] ?? [];
          case 'UPPER_LOWER':
            return i.isEven
                ? ['chest', 'back', 'shoulders', 'biceps', 'triceps']
                : ['legs', 'core'];
          case 'PUSH_PULL_LEGS':
            return [
              ['chest', 'shoulders', 'triceps'],
              ['back', 'biceps'],
              ['legs', 'core']
            ][i % 3];
          case 'MUSCLE_FOCUSED':
            return focused(count)[i % focused(count).length];
          default:
            return ['chest', 'back', 'legs'];
        }
      });
  static List<List<String>> focused(int days) {
    if (days == 2) {
      return [
        ['chest', 'shoulders', 'triceps'],
        ['back', 'legs', 'biceps', 'core']
      ];
    }
    if (days == 3) {
      return [
        ['chest', 'shoulders', 'triceps'],
        ['back', 'biceps'],
        ['legs', 'core']
      ];
    }
    if (days == 4) {
      return [
        ['chest', 'triceps'],
        ['back', 'biceps'],
        ['legs', 'core'],
        ['shoulders']
      ];
    }
    if (days == 5) {
      return [
        ['chest', 'triceps'],
        ['back', 'biceps'],
        ['legs'],
        ['shoulders'],
        ['core']
      ];
    }
    return [
      ['chest'],
      ['back'],
      ['legs'],
      ['shoulders'],
      ['biceps', 'triceps'],
      ['core']
    ];
  }

  bool get incompleteCustom =>
      resolved == 'CUSTOM' &&
      !{'chest', 'back', 'legs'}.every(groups.expand((g) => g).contains);
}
