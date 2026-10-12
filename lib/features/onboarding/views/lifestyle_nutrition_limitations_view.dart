import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/onboarding_page_route.dart';
import '../components/activity_sleep_controls.dart';
import '../components/body_limitations_controls.dart';
import '../components/nutrition_budget_controls.dart';
import '../components/onboarding_scaffold.dart';
import '../viewmodels/lifestyle_nutrition_viewmodel.dart';
import 'training_preferences_view.dart';

// MARK: - Apple iOS Lifestyle & Recovery Preferences
class LifestyleNutritionLimitationsView extends StatefulWidget {
  const LifestyleNutritionLimitationsView({super.key});

  @override
  State<LifestyleNutritionLimitationsView> createState() =>
      _LifestyleNutritionLimitationsViewState();
}

class _LifestyleNutritionLimitationsViewState
    extends State<LifestyleNutritionLimitationsView> {
  late final LifestyleNutritionViewModel _viewModel;
  late final TextEditingController _customDietController;

  @override
  void initState() {
    super.initState();
    _viewModel = LifestyleNutritionViewModel()..addListener(_rebuild);
    _customDietController =
        TextEditingController(text: _viewModel.customEatingStyle);
  }

  void _rebuild() {
    if (!mounted) return;
    if (_customDietController.text != _viewModel.customEatingStyle) {
      _customDietController.value = TextEditingValue(
        text: _viewModel.customEatingStyle,
        selection: TextSelection.collapsed(
          offset: _viewModel.customEatingStyle.length,
        ),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_rebuild);
    _viewModel.dispose();
    _customDietController.dispose();
    super.dispose();
  }

  void _onBack() {
    Navigator.of(context).pop();
  }

  void _onContinue() async {
    await _viewModel.continueToNextStep();
    if (!mounted) return;
    Navigator.of(context).push(
      OnboardingPageRoute(page: const TrainingPreferencesView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    final activity = _viewModel.activityLevel;
    final sleep = _viewModel.sleepDuration;
    final eating = _viewModel.eatingStyle;
    final limitations = _viewModel.limitations;

    return OnboardingScaffold(
      step: _viewModel.currentStep,
      totalSteps: _viewModel.totalSteps,
      title: language.headlineLifestyleAndNutrition,
      subtitle: language.subtitleLifestyleAndNutrition,
      actionTitle: language.continueButtonTitle,
      onBack: _onBack,
      onContinue: _viewModel.isValid ? _onContinue : null,
      children: [
        // ── 1. Daily Activity Outside Workouts ────────────────────
        FitnessText(
          language.activityLevelQuestion
              .replaceAll('?', '')
              .trim()
              .toUpperCase(),
          style: const TextStyle(
            fontFamily: null,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF8E8E93),
          ),
        ),

        const SizedBox(height: 10),

        ActivityLevelSegmented(
          selectedOption: activity,
          onSelected: _viewModel.selectActivity,
        ),

        const SizedBox(height: 24),

        // ── 2. Sleep Duration ─────────────────────────────────────
        FitnessText(
          language.sleepDurationQuestion
              .replaceAll('?', '')
              .trim()
              .toUpperCase(),
          style: const TextStyle(
            fontFamily: null,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF8E8E93),
          ),
        ),

        const SizedBox(height: 10),

        SleepDurationChips(
          selectedOption: sleep,
          onSelected: _viewModel.selectSleep,
        ),

        const SizedBox(height: 24),

        // ── 3. Eating Style ───────────────────────────────────────
        FitnessText(
          language.eatingStyleQuestion.replaceAll('?', '').trim().toUpperCase(),
          style: const TextStyle(
            fontFamily: null,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF8E8E93),
          ),
        ),

        const SizedBox(height: 10),

        EatingStyleGrid(
          language: language,
          selectedOption: eating,
          onSelected: _viewModel.selectEatingStyle,
        ),

        if (eating.isCustom) ...[
          const SizedBox(height: 10),
          OtherDietInput(
            controller: _customDietController,
            placeholder: language.customDietPlaceholder,
            onChanged: _viewModel.setCustomEatingStyle,
          ),
        ],

        const SizedBox(height: 24),

        // ── 4. Body Limitations & Joint Care ──────────────────────
        FitnessText(
          language.limitationsSectionTitle.toUpperCase(),
          style: const TextStyle(
            fontFamily: null,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF8E8E93),
          ),
        ),

        const SizedBox(height: 10),

        BodyLimitationsChips(
          selectedLimitations: limitations,
          onToggle: _viewModel.toggleLimitation,
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
