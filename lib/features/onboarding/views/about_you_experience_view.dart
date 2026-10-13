import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/components/fit_toast.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../components/about_you_controls.dart';
import '../components/biometric_ruler_card.dart';
import '../components/experience_card.dart';
import '../components/onboarding_scaffold.dart';
import '../models/experience_level.dart';
import '../viewmodels/about_you_viewmodel.dart';
import 'schedule_location_view.dart';
import '../../../core/theme/fitness_theme.dart';

// MARK: - Combined Screen 02 & 03: About You & Your Experience (Apple iOS Premium)
class AboutYouExperienceView extends StatefulWidget {
  const AboutYouExperienceView({super.key});

  @override
  State<AboutYouExperienceView> createState() => _AboutYouExperienceViewState();
}

class _AboutYouExperienceViewState extends State<AboutYouExperienceView>
    with TickerProviderStateMixin {
  late final AboutYouViewModel _viewModel;
  late final TextEditingController _nameController;
  late final AnimationController _expStaggerCtrl;
  String _selectedMetric = 'weight';

  @override
  void initState() {
    super.initState();
    _viewModel = AboutYouViewModel()..addListener(_rebuild);
    _nameController = TextEditingController(text: _viewModel.name);
    _expStaggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _expStaggerCtrl.forward();
    });

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
    _expStaggerCtrl.dispose();
    super.dispose();
  }

  void _onBack() {
    Navigator.of(context).pop();
  }

  void _onContinue() async {
    final language = _viewModel.selectedLanguage;
    if (!_viewModel.isValid) {
      HapticFeedback.mediumImpact();
      final String msg = _viewModel.name.trim().length < 2
          ? language.nameValidationPrompt
          : 'Please pick your experience level to continue.';
      FitToast.show(
        context,
        message: msg,
        icon: _viewModel.name.trim().length < 2
            ? CupertinoIcons.person
            : CupertinoIcons.sparkles,
      );
      return;
    }

    await _viewModel.continueToNextStep();
    if (!mounted) return;
    Navigator.of(context).push(
      OnboardingPageRoute(page: const ScheduleLocationView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    final selectedExperience = _viewModel.selectedExperience;

    return OnboardingScaffold(
      step: _viewModel.currentStep,
      totalSteps: _viewModel.totalSteps,
      title: language.headlineAboutYou,
      subtitle: 'A few details to build a plan around you.',
      actionTitle: language.continueButtonTitle,
      onBack: _onBack,
      onContinue: _onContinue,
      children: [
        // ── SECTION 1: ABOUT YOU ─────────────────────────────
        // Name Input (Zero icons, Apple liquid glass)
        LiquidNameInput(
          controller: _nameController,
          label: language.nameLabel,
          placeholder: language.namePlaceholder,
          onChanged: _viewModel.setName,
        ),

        const SizedBox(height: 12),

        // Full-Width Apple Gender Selector (Male / Female)
        AppleGenderSelector(
          selectedGender: _viewModel.gender,
          maleLabel: language.genderMale,
          femaleLabel: language.genderFemale,
          onSelected: _viewModel.setGender,
        ),

        const SizedBox(height: 24),

        // ── BIOMETRICS SECTION WITH APPLE UNIT SWITCHER ──────
        BiometricsHeaderWithUnits(
          title: language.biometricsSectionTitle,
          isImperial: _viewModel.isImperial,
          imperialLabel: language.unitImperialLabel,
          metricLabel: language.unitMetricLabel,
          onUnitChanged: _viewModel.setImperial,
        ),

        const SizedBox(height: 10),

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

        const SizedBox(height: 28),

        // ── SECTION 2: YOUR EXPERIENCE (Text-only header, no stars) ──
        FitnessText(
          language.experienceSectionTitle.toUpperCase(),
          style: const TextStyle(
            fontFamily: null,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Color(0xFF8E8E93),
          ),
        ),

        const SizedBox(height: 12),

        // 3 Experience Cards — staggered slide-up entrance
        ...List.generate(ExperienceLevel.values.length, (index) {
          final level = ExperienceLevel.values[index];
          final isSelected = selectedExperience == level;
          final title = language.experienceTitle(level);
          final subtitle = language.experienceSubtitle(level);
          final start = index * 0.20;
          final end = (start + 0.55).clamp(0.0, 1.0);
          final cardAnim = CurvedAnimation(
            parent: _expStaggerCtrl,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FadeTransition(
              opacity: cardAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.22),
                  end: Offset.zero,
                ).animate(cardAnim),
                child: ExperienceCard(
                  level: level,
                  title: title,
                  subtitle: subtitle,
                  isSelected: isSelected,
                  onTap: () => _viewModel.selectExperience(level),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
      ],
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
