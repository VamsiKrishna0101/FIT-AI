import '../viewmodels/onboarding_controller.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../components/nutrition_budget_controls.dart';
import '../models/lifestyle_nutrition_models.dart';
import '../components/onboarding_scaffold.dart';
import '../viewmodels/lifestyle_nutrition_viewmodel.dart';
import 'training_preferences_view.dart';

// MARK: - Apple iOS Lifestyle & Recovery Preferences
class LifestyleNutritionLimitationsView extends StatefulWidget {
  final OnboardingController? controller;
  final VoidCallback? onContinue;
  const LifestyleNutritionLimitationsView(
      {super.key, this.controller, this.onContinue});

  @override
  State<LifestyleNutritionLimitationsView> createState() =>
      _LifestyleNutritionLimitationsViewState();
}

class _LifestyleNutritionLimitationsViewState
    extends State<LifestyleNutritionLimitationsView> {
  bool _advancing = false;
  int _part = 0;
  late final LifestyleNutritionViewModel _viewModel;
  late final TextEditingController _customDietController;

  @override
  void initState() {
    super.initState();
    _viewModel = LifestyleNutritionViewModel(controller: widget.controller)
      ..addListener(_rebuild);
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
    if (_part > 0) {
      setState(() => _part--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onContinue() async {
    if (_advancing) return;
    if (_part < 2) {
      FocusScope.of(context).unfocus();
      setState(() => _part++);
      return;
    }
    setState(() => _advancing = true);
    try {
      await _viewModel.continueToNextStep();
      if (!mounted) return;
      if (widget.onContinue != null) {
        widget.onContinue!();
        return;
      }
      await OnboardingPageRoute(
              page: TrainingPreferencesView(controller: _viewModel.controller))
          .open(context);
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    return OnboardingScaffold(
      step: _viewModel.currentStep,
      totalSteps: _viewModel.totalSteps,
      sectionLabel: 'Your lifestyle',
      part: _part,
      parts: 3,
      canPop: _part == 0,
      title: switch (_part) {
        0 => language.activityLevelQuestion,
        1 => language.eatingStyleQuestion,
        _ => language.limitationsSectionTitle,
      },
      subtitle: switch (_part) {
        0 =>
          'Your everyday activity and usual sleep help us understand your starting routine.',
        1 => 'Your preferences help shape your nutrition.',
        _ => 'Choose any areas we should take into account.',
      },
      actionTitle: language.continueButtonTitle,
      loading: _advancing,
      onBack: _onBack,
      onContinue: _viewModel.controller.ready ? _onContinue : null,
      children: [
        if (_part == 0)
          for (final option in ActivityLevelOption.values)
            _choice(
                option.defaultLabel,
                option.defaultSubtitle,
                _viewModel.activityLevel == option,
                () => _viewModel.selectActivity(option)),
        if (_part == 0) ...[
          const SizedBox(height: 20),
          FitnessText(language.sleepDurationQuestion,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in SleepDurationOption.values)
              ChoiceChip(
                  label: Text(option.defaultLabel),
                  showCheckmark: false,
                  selected: _viewModel.sleepDuration == option,
                  selectedColor: FitnessTheme.silver,
                  labelStyle: TextStyle(
                      color: _viewModel.sleepDuration == option
                          ? Colors.black
                          : Colors.white),
                  onSelected: (_) => _viewModel.selectSleep(option)),
          ]),
        ],
        if (_part == 1) ...[
          for (final option in EatingStyleOption.values)
            _choice(
                language.eatingStyleLabel(option.backendValue),
                null,
                _viewModel.eatingStyle == option,
                () => _viewModel.selectEatingStyle(option)),
          if (_viewModel.eatingStyle.isCustom)
            OtherDietInput(
                controller: _customDietController,
                placeholder: language.customDietPlaceholder,
                onChanged: _viewModel.setCustomEatingStyle),
        ],
        if (_part == 2)
          for (final option in BodyLimitationOption.values)
            _choice(
                option.defaultLabel,
                null,
                _viewModel.limitations.contains(option),
                () => _viewModel.toggleLimitation(option)),
      ],
    );
  }

  Widget _choice(
          String title, String? subtitle, bool selected, VoidCallback onTap) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OnboardingChoice(
              title: title,
              subtitle: subtitle,
              selected: selected,
              onTap: onTap));
}
