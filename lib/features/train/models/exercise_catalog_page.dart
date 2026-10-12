import 'workout_exercise_models.dart';

class ExerciseFilterOption {
  final String value, label;
  const ExerciseFilterOption(this.value, this.label);
  factory ExerciseFilterOption.fromJson(Map<String, dynamic> json) =>
      ExerciseFilterOption(json['value'] as String, json['label'] as String);
}

class ExerciseCatalogPage {
  final List<WorkoutExerciseModel> exercises;
  final int page, total, totalPages;
  final List<ExerciseFilterOption> bodyParts, equipment;
  const ExerciseCatalogPage(
      {required this.exercises,
      required this.page,
      required this.total,
      required this.totalPages,
      required this.bodyParts,
      required this.equipment});
  factory ExerciseCatalogPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map;
    List<ExerciseFilterOption> options(String name) => (json['filters'][name]
            as List)
        .map((e) =>
            ExerciseFilterOption.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return ExerciseCatalogPage(
        exercises: (json['data'] as List)
            .map((e) => WorkoutExerciseModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        page: (pagination['page'] as num).toInt(),
        total: (pagination['total'] as num).toInt(),
        totalPages: (pagination['totalPages'] as num).toInt(),
        bodyParts: options('bodyParts'),
        equipment: options('equipment'));
  }
}
