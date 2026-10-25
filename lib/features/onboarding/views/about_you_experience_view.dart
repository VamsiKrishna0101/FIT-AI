import '../viewmodels/onboarding_controller.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/onboarding_page_route.dart';
import '../components/about_you_controls.dart';
import '../components/biometric_ruler_card.dart';
import '../components/onboarding_scaffold.dart';
import '../components/training_hero.dart';
import '../components/onboarding_focus_body.dart';
import '../models/experience_level.dart';
import '../viewmodels/about_you_viewmodel.dart';
import 'schedule_location_view.dart';
import '../../../core/theme/fitness_theme.dart';

// MARK: - Combined Screen 02 & 03: About You & Your Experience (Apple iOS Premium)
class AboutYouExperienceView extends StatefulWidget {
  final OnboardingController? controller;
  final VoidCallback? onContinue;
  const AboutYouExperienceView({super.key, this.controller, this.onContinue});

  @override
  State<AboutYouExperienceView> createState() => _AboutYouExperienceViewState();
}

class _AboutYouExperienceViewState extends State<AboutYouExperienceView> {
  bool _advancing = false;
  int _part = 0;
  late final AboutYouViewModel _viewModel;
  late final TextEditingController _nameController;
  String _selectedMetric = 'weight';

  @override
  void initState() {
    super.initState();
    _viewModel = AboutYouViewModel(controller: widget.controller)
      ..addListener(_rebuild);
    _nameController = TextEditingController(text: _viewModel.name);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_viewModel.name.isNotEmpty) {
          _nameController.text = _viewModel.name;
        }
      }
    });
  }

  void _rebuild() {
    if (!mounted) return;
    if (_nameController.text != _viewModel.name && _viewModel.name.isNotEmpty) {
      _nameController.text = _viewModel.name;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_rebuild);
    _viewModel.dispose();
    _nameController.dispose();
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
    if (_part < 3) {
      FocusScope.of(context).unfocus();
      setState(() => _part++);
      return;
    }
    if (!_viewModel.isValid) return;

    setState(() => _advancing = true);
    try {
      await _viewModel.continueToNextStep();
      if (!mounted) return;
      if (widget.onContinue != null) {
        widget.onContinue!();
        return;
      }
      await OnboardingPageRoute(
              page: ScheduleLocationView(controller: _viewModel.controller))
          .open(context);
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    final titles = [
      'Let’s make it yours.',
      'A little about you',
      'Your starting point',
      language.experienceSectionTitle,
    ];
    final subtitles = [
      language.namePlaceholder,
      'This helps personalize your experience.',
      'Confirm your age, height, weight and target.',
      'Choose the description that feels most like you.',
    ];
    return OnboardingScaffold(
      step: _viewModel.currentStep,
      totalSteps: _viewModel.totalSteps,
      sectionLabel: 'About you',
      part: _part,
      parts: 4,
      canPop: _part == 0,
      title: titles[_part],
      subtitle: subtitles[_part],
      actionTitle: language.continueButtonTitle,
      loading: _advancing,
      onBack: _onBack,
      onContinue: !_viewModel.controller.ready ||
              (_part == 0 && _viewModel.name.trim().length < 2)
          ? null
          : _onContinue,
      children: [
        if (_part == 0)
          LiquidNameInput(
              controller: _nameController,
              label: language.nameLabel,
              placeholder: language.namePlaceholder,
              onChanged: (value) {
                final valid = _viewModel.name.trim().length >= 2;
                _viewModel.setName(value);
                if (valid != (_viewModel.name.trim().length >= 2)) {
                  setState(() {});
                }
              }),
        if (_part == 1) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final gender in ['MALE', 'FEMALE'])
              Expanded(
                  child: _genderChoice(
                      gender,
                      gender == 'MALE'
                          ? language.genderMale
                          : language.genderFemale)),
          ]),
        ],
        if (_part == 2) ...[
          BiometricsHeaderWithUnits(
              title: language.biometricsSectionTitle,
              isImperial: _viewModel.isImperial,
              imperialLabel: language.unitImperialLabel,
              metricLabel: language.unitMetricLabel,
              onUnitChanged: _viewModel.setImperial),
          const SizedBox(height: 16),
          _biometrics(),
        ],
        if (_part == 3)
          for (final level in ExperienceLevel.values)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OnboardingChoice(
                    title: language.experienceTitle(level),
                    subtitle: language.experienceSubtitle(level),
                    selected: _viewModel.selectedExperience == level,
                    onTap: () => _viewModel.selectExperience(level))),
        if (_part == 3) ...[
          const SizedBox(height: 8),
          OnboardingContextNote(
              title: 'The right starting point matters.',
              detail: switch (_viewModel.selectedExperience) {
                ExperienceLevel.beginner =>
                  'Your experience helps us choose approachable exercises and a manageable starting workload.',
                ExperienceLevel.intermediate =>
                  'Your plan can build on movements you know, with a clear structure for progressing.',
                ExperienceLevel.advanced =>
                  'Your experience helps guide exercise selection, workload and progression.',
                null =>
                  'Choose your experience so your plan starts at the right level for you.',
              }),
        ],
      ],
    );
  }

  Widget _genderChoice(String gender, String label) {
    final selected = _viewModel.gender == gender;
    return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                key: ValueKey('onboarding-gender-$gender'),
                borderRadius: BorderRadius.circular(24),
                onTap: () => _viewModel.setGender(gender),
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(children: [
                      Opacity(
                          opacity: selected ? 1 : .38,
                          child: SizedBox(
                              height: ((MediaQuery.sizeOf(context).width - 80) /
                                      2 *
                                      2.2)
                                  .clamp(240.0, 360.0),
                              child: Image.asset(
                                  onboardingBodyAsset(
                                      female: gender == 'FEMALE'),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  cacheWidth: 500,
                                  excludeFromSemantics: true))),
                      const SizedBox(height: 20),
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              color: selected
                                  ? FitnessTheme.silver
                                  : FitnessTheme.surface,
                              borderRadius: BorderRadius.circular(30)),
                          child: FitnessText(label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      selected ? Colors.black : Colors.white))),
                    ])))));
  }

  Widget _biometrics() {
    final language = _viewModel.selectedLanguage;
    return ValueListenableBuilder<int>(
      valueListenable: _viewModel.measurements,
      builder: (context, value, child) => Column(children: [
        _ruler(),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: _metricChoice('height', language.heightLabel,
                  '${_viewModel.heightDisplay} ${_viewModel.heightUnitDisplay ?? ''}')),
          const SizedBox(width: 10),
          Expanded(
              child: _metricChoice('weight', language.weightLabel,
                  '${_viewModel.weightDisplay} ${_viewModel.weightUnitDisplay}')),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: _metricChoice('age', language.ageLabel,
                  '${_viewModel.age} ${language.yearsUnit}')),
          const SizedBox(width: 10),
          Expanded(
              child: _metricChoice('target', language.targetWeightLabel,
                  '${_viewModel.targetWeightDisplay} ${_viewModel.weightUnitDisplay}')),
        ]),

        const SizedBox(height: 10),

        // Goal Delta Summary Badge
        AppleGoalSummaryBadge(
          text: _viewModel.weightGoalSummary,
        ),
      ]),
    );
  }

  Widget _ruler() {
    final model = _viewModel;
    final language = model.selectedLanguage;
    final imperial = model.isImperial;
    final rulerKey = ValueKey('ruler-$_selectedMetric-$imperial');

    if (_selectedMetric == 'age') {
      return BiometricRulerCard(
          key: rulerKey,
          label: language.ageLabel,
          value: model.age.toDouble(),
          valueDisplay: '${model.age}',
          unit: language.yearsUnit,
          min: 13,
          max: 100,
          step: 1,
          majorEvery: 5,
          tickLabel: (value) => '${value.round()}',
          onChanged: model.setAge);
    }

    if (_selectedMetric == 'height') {
      return BiometricRulerCard(
          key: rulerKey,
          label: language.heightLabel,
          value: imperial
              ? (model.heightCm / 2.54).roundToDouble()
              : model.heightCm,
          valueDisplay: model.heightDisplay,
          unit: model.heightUnitDisplay,
          secondaryDisplay: model.secondaryHeightDisplay,
          min: imperial ? 48 : 120,
          max: imperial ? 90 : 230,
          step: 1,
          majorEvery: imperial ? 6 : 10,
          tickLabel: (value) => imperial
              ? '${value.round() ~/ 12}′${value.round() % 12}″'
              : '${value.round()}',
          onChanged: model.setHeight);
    }

    final target = _selectedMetric == 'target';
    final weight = target ? model.targetWeightKg : model.weightKg;
    return BiometricRulerCard(
        key: rulerKey,
        label: target ? language.targetWeightLabel : language.weightLabel,
        value: imperial ? (weight * 2.20462).roundToDouble() : weight,
        valueDisplay: target ? model.targetWeightDisplay : model.weightDisplay,
        unit: model.weightUnitDisplay,
        secondaryDisplay: target
            ? model.secondaryTargetWeightDisplay
            : model.secondaryWeightDisplay,
        min: imperial ? 67 : 30,
        max: imperial ? 551 : 250,
        step: imperial ? 1 : .1,
        majorEvery: 10,
        tickLabel: (value) => '${value.round()}',
        onChanged: target ? model.setTargetWeight : model.setWeight);
  }

  Widget _metricChoice(String metric, String label, String value) {
    final selected = _selectedMetric == metric;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFF2B2C2E) : FitnessTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: selected ? const Color(0xFFB4B4B4) : FitnessTheme.line)),
        child: InkWell(
          key: ValueKey('select-biometric-$metric'),
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedMetric = metric);
          },
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FitnessText(label,
                        style: const TextStyle(
                            fontSize: 11, color: FitnessTheme.muted)),
                    const SizedBox(height: 6),
                    Text(value.trim(),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w500)),
                  ])),
        ),
      ),
    );
  }
}
