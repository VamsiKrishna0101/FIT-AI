import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../viewmodels/onboarding_controller.dart';
import '../models/working_toward_goal.dart';
import '../models/experience_level.dart';
import '../models/training_schedule_models.dart';
import 'goal_selection_view.dart';
import 'about_you_experience_view.dart';
import 'schedule_location_view.dart';
import 'equipment_selection_view.dart';
import 'training_preferences_view.dart';
import 'lifestyle_nutrition_limitations_view.dart';

/// Reuses the validated setup controls in a training-first conversation.
/// Each route retains its state when the user goes back; all share one draft.
abstract final class OnboardingJourney {
  static Widget start(OnboardingController controller) => _page(0, controller);
  static Widget _page(int stage, OnboardingController controller) =>
      Builder(builder: (context) {
        final draft = controller.draft;
        final language = LanguageManager.shared.currentLanguage;
        void next() => unawaited(
            OnboardingPageRoute<void>(page: _page(stage + 1, controller))
                .open(context));
        final goal = language
            .goalTitle(WorkingTowardGoal.fromBackend(draft.workingToward));
        final experience = language.experienceTitle(
            ExperienceLevel.fromBackend(draft.experienceLevel));
        final location = draft.trainingLocation == null
            ? null
            : language.locationOptionTitle(
                TrainingLocationOption.fromBackend(draft.trainingLocation!));
        return switch (stage) {
          0 => GoalSelectionView(
              controller: controller, coaching: true, onContinue: next),
          1 => AboutYouExperienceView(
              controller: controller,
              coaching: true,
              questionParts: const [3],
              previousAnswer: goal,
              onContinue: next),
          2 => ScheduleLocationView(
              controller: controller,
              coaching: true,
              questionParts: const [2],
              previousAnswer: experience,
              onContinue: next),
          3 => EquipmentSelectionView(
              controller: controller,
              coaching: true,
              previousAnswer: location,
              onContinue: next),
          4 => ScheduleLocationView(
              controller: controller,
              coaching: true,
              questionParts: const [0, 1],
              previousAnswer: fitnessText(context, 'Equipment saved'),
              onContinue: next),
          5 => TrainingPreferencesView(
              controller: controller,
              coaching: true,
              questionParts: const [1, 2],
              previousAnswer: language.durationOptionTitle(
                  WorkoutDurationOption.fromBackend(
                      draft.workoutDuration ?? 'MIN_45')),
              onContinue: next),
          6 => AboutYouExperienceView(
              controller: controller,
              coaching: true,
              questionParts: const [0, 1, 4],
              previousAnswer: fitnessText(context, 'Your week is set'),
              onContinue: next),
          7 => TrainingPreferencesView(
              controller: controller,
              coaching: true,
              questionParts: const [0],
              previousAnswer: draft.name,
              onContinue: next),
          8 => LifestyleNutritionLimitationsView(
              controller: controller,
              coaching: true,
              previousAnswer:
                  fitnessText(context, 'Training preferences saved'),
              onContinue: next),
          _ => TrainingPreferencesView(
              controller: controller,
              coaching: true,
              questionParts: const [3],
              previousAnswer: fitnessText(context, 'Preferences saved')),
        };
      });
}
