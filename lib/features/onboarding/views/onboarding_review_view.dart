import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../auth/views/auth_view.dart';
import '../components/onboarding_scaffold.dart';
import '../models/experience_level.dart';
import '../models/equipment_copy.dart';
import '../models/lifestyle_nutrition_models.dart';
import '../models/working_toward_goal.dart';
import '../models/training_schedule_models.dart';
import '../viewmodels/onboarding_controller.dart';
import 'about_you_experience_view.dart';
import 'schedule_location_view.dart';
import 'equipment_selection_view.dart';
import 'lifestyle_nutrition_limitations_view.dart';

class OnboardingReviewView extends StatefulWidget {
  final OnboardingController controller;
  const OnboardingReviewView({super.key, required this.controller});
  @override
  State<OnboardingReviewView> createState() => _OnboardingReviewViewState();
}

class _OnboardingReviewViewState extends State<OnboardingReviewView> {
  bool _confirmed = false;
  Future<void> _edit(Widget page) async {
    await Navigator.of(context).push(AppPageRoute<void>(page: page));
    if (mounted) setState(() => _confirmed = false);
  }

  void _backFromEdit() => Navigator.of(context).pop();
  @override
  Widget build(BuildContext context) {
    final draft = widget.controller.draft;
    final language = LanguageManager.shared.currentLanguage;
    final format = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag());
    return OnboardingScaffold(
      step: 7,
      showProgress: false,
      title: 'Check your starting point',
      subtitle: 'Confirm these details before we build your first plan.',
      actionTitle: 'Create account',
      onBack: () => Navigator.of(context).pop(),
      onContinue: !_confirmed
          ? null
          : () => OnboardingPageRoute<void>(
                  page: AuthView(controller: widget.controller))
              .open(context),
      children: [
        FitnessCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FitnessText('Your goal',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FitnessText(language
              .goalTitle(WorkingTowardGoal.fromBackend(draft.workingToward))),
          TextButton(
              onPressed: () async {
                final value = await showModalBottomSheet<WorkingTowardGoal>(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (sheet) => SafeArea(
                            child: SingleChildScrollView(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                              for (final goal in WorkingTowardGoal.values)
                                ListTile(
                                    title: Text(language.goalTitle(goal)),
                                    onTap: () => Navigator.of(sheet).pop(goal)),
                            ]))));
                if (!mounted || value == null) return;
                setState(() {
                  draft.workingToward = value.backendValue;
                  _confirmed = false;
                });
                widget.controller.checkpoint();
              },
              child: const FitnessText('Change')),
        ])),
        const SizedBox(height: 12),
        _section(
            'About You',
            [
              '${draft.name ?? ''} · ${draft.gender == 'FEMALE' ? language.genderFemale : language.genderMale}',
              '${draft.age ?? '—'} · ${draft.heightCm == null ? '—' : format.format(draft.heightCm)} cm · ${draft.weightKg == null ? '—' : format.format(draft.weightKg)} kg',
              language.experienceTitle(
                  ExperienceLevel.fromBackend(draft.experienceLevel)),
              if (draft.targetWeightKg != null)
                '${fitnessText(context, 'Target weight')}: ${format.format(draft.targetWeightKg)} kg',
            ],
            () => _edit(AboutYouExperienceView(
                controller: widget.controller, onContinue: _backFromEdit))),
        const SizedBox(height: 12),
        _section(
            'Your Schedule & Space',
            [
              '${DaysPerWeekOption.fromBackend(draft.daysPerWeek)?.daysCount ?? '—'} × ${language.durationOptionTitle(WorkoutDurationOption.fromBackend(draft.workoutDuration))}',
              language.locationOptionTitle(
                  TrainingLocationOption.fromBackend(draft.trainingLocation)),
            ],
            () => _edit(ScheduleLocationView(
                controller: widget.controller, onContinue: _backFromEdit))),
        const SizedBox(height: 12),
        _section(
            'Your equipment',
            [
              draft.equipmentIds
                  .map((id) => EquipmentCopy.item(language, id))
                  .join(' · '),
            ],
            () => _edit(EquipmentSelectionView(
                controller: widget.controller, onContinue: _backFromEdit))),
        const SizedBox(height: 12),
        _section(
            'Your Lifestyle',
            [
              EatingStyleOption.fromBackend(draft.eatingStyle).defaultLabel,
              ActivityLevelOption.fromBackend(draft.activityLevel).defaultLabel,
              SleepDurationOption.fromBackend(draft.sleepDuration).defaultLabel,
              draft.limitations
                  .map((value) =>
                      BodyLimitationOption.fromBackend(value).defaultLabel)
                  .join(' · '),
              if (draft.customLimitations?.trim().isNotEmpty == true)
                draft.customLimitations!,
            ],
            () => _edit(LifestyleNutritionLimitationsView(
                controller: widget.controller, onContinue: _backFromEdit))),
        const SizedBox(height: 12),
        CheckboxListTile(
            value: _confirmed,
            activeColor: FitnessTheme.silver,
            checkColor: FitnessTheme.canvas,
            contentPadding: EdgeInsets.zero,
            title: const FitnessText('I have checked these details.'),
            onChanged: (value) => setState(() => _confirmed = value == true)),
      ],
    );
  }

  Widget _section(String title, List<String> values, VoidCallback edit) =>
      FitnessCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FitnessText(title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final value in values)
            Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: FitnessText(value,
                    style: const TextStyle(
                        fontSize: 14, color: FitnessTheme.muted))),
          TextButton(onPressed: edit, child: const FitnessText('Change')),
        ]),
      );
}
