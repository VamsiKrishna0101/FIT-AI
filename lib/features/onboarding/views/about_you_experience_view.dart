import '../../../core/localization/fitness_copy.dart';
import 'package:flutter/cupertino.dart';
import '../viewmodels/onboarding_controller.dart';
import 'package:setcraft/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/onboarding_page_route.dart';
import '../components/about_you_controls.dart';
import '../components/biometric_ruler_card.dart';
import '../components/onboarding_scaffold.dart';
import '../components/training_hero.dart';
import '../components/onboarding_answer_flow.dart';
import '../components/onboarding_focus_body.dart';
import '../models/experience_level.dart';
import '../viewmodels/about_you_viewmodel.dart';
import 'schedule_location_view.dart';
import '../../../core/theme/fitness_theme.dart';

// MARK: - Combined Screen 02 & 03: About You & Your Experience (Apple iOS Premium)
class AboutYouExperienceView extends StatefulWidget {
  final OnboardingController? controller;
  final VoidCallback? onContinue;
  final bool coaching;
  final List<int> questionParts;
  final String? previousAnswer;
  const AboutYouExperienceView(
      {super.key,
      this.controller,
      this.onContinue,
      this.coaching = false,
      this.questionParts = const [0, 1, 2, 3],
      this.previousAnswer});

  @override
  State<AboutYouExperienceView> createState() => _AboutYouExperienceViewState();
}

class _AboutYouExperienceViewState extends State<AboutYouExperienceView>
    with OnboardingAnswerFlow<AboutYouExperienceView> {
  bool _advancing = false;
  int _part = 0;
  late final AboutYouViewModel _viewModel;
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  String _selectedMetric = 'weight';
  bool _editingMeasurement = false;

  @override
  void initState() {
    super.initState();
    _part = widget.questionParts.first;
    _viewModel = AboutYouViewModel(controller: widget.controller)
      ..addListener(_rebuild);
    _nameController = TextEditingController(text: _viewModel.name);
    _ageController = TextEditingController(
        text: widget.controller?.draft.age?.toString() ?? '');

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
    _ageController.dispose();
    super.dispose();
  }

  bool get _validAge {
    final age = int.tryParse(_ageController.text);
    return age != null && age >= 13 && age <= 100;
  }

  void _onBack() {
    if (widget.questionParts.indexOf(_part) > 0) {
      setState(() => _part =
          widget.questionParts[widget.questionParts.indexOf(_part) - 1]);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onContinue() async {
    if (_advancing || (_part == 4 && !_validAge)) return;
    if (widget.questionParts.indexOf(_part) < widget.questionParts.length - 1) {
      FocusScope.of(context).unfocus();
      setState(() => _part =
          widget.questionParts[widget.questionParts.indexOf(_part) + 1]);
      return;
    }
    final experienceOnly = widget.questionParts.length == 1 && _part == 3;
    if (!experienceOnly && !_viewModel.isValid) return;

    setState(() => _advancing = true);
    try {
      if (experienceOnly) {
        _viewModel.draft.experienceLevel =
            _viewModel.selectedExperience?.backendValue;
        _viewModel.controller.checkpoint();
      } else {
        await _viewModel.continueToNextStep(
            includeMeasurements: widget.questionParts.contains(2));
      }
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
      'How old are you?',
    ];
    final subtitles = [
      language.namePlaceholder,
      'This helps personalize your experience.',
      'Confirm your age, height, weight and target.',
      'Choose the description that feels most like you.',
      '',
    ];
    return OnboardingScaffold(
      step: _viewModel.currentStep,
      totalSteps: _viewModel.totalSteps,
      sectionLabel: 'About you',
      part: _part,
      parts: 5,
      canPop: _part == widget.questionParts.first,
      title: widget.coaching
          ? [
              'What should we call you?',
              'Which profile fits you?',
              'Your body stats',
              language.experienceSectionTitle,
              'How old are you?',
            ][_part]
          : titles[_part],
      subtitle: widget.coaching ? '' : subtitles[_part],
      animateQuestion: widget.coaching,
      previousAnswer: widget.coaching
          ? (_part == 0 || _part == 3
              ? widget.previousAnswer
              : _part == 1
                  ? _viewModel.name
                  : (_viewModel.gender == 'FEMALE'
                      ? language.genderFemale
                      : language.genderMale))
          : null,
      showContinue: !widget.coaching || (_part != 1 && _part != 3),
      footer: widget.coaching && (_part == 1 || _part == 3)
          ? 'You can change this later.'
          : null,
      actionTitle: language.continueButtonTitle,
      loading: _advancing || choosingAnswer,
      onBack: _onBack,
      onContinue: !_viewModel.controller.ready ||
              (_part == 0 && _viewModel.name.trim().length < 2) ||
              (_part == 4 && !_validAge)
          ? null
          : _onContinue,
      children: [
        if (_part == 4)
          TextField(
              key: const ValueKey('onboarding-age'),
              controller: _ageController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3)
              ],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                  hintText: language.ageLabel,
                  suffixText: language.yearsUnit,
                  errorText: _ageController.text.isNotEmpty && !_validAge
                      ? fitnessText(context, 'Enter an age from 13 to 100')
                      : null),
              onChanged: (text) {
                final age = int.tryParse(text);
                if (age != null && age >= 13 && age <= 100) {
                  _viewModel.setAge(age.toDouble());
                } else {
                  _viewModel.draft.age = null;
                  _viewModel.controller.checkpoint();
                }
                setState(() {});
              },
              onSubmitted: (_) {
                if (_validAge) _onContinue();
              }),
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
          if (widget.coaching)
            _measurementSummary()
          else ...[
            BiometricsHeaderWithUnits(
                title: language.biometricsSectionTitle,
                showUnitSelector: _selectedMetric != 'age',
                isImperial: _viewModel.isImperial,
                imperialLabel: language.unitImperialLabel,
                metricLabel: language.unitMetricLabel,
                onUnitChanged: _viewModel.setImperial),
            const SizedBox(height: 16),
            _biometrics(),
          ],
        ],
        if (_part == 3)
          for (final level in ExperienceLevel.values)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OnboardingChoice(
                    title: language.experienceTitle(level),
                    subtitle: widget.coaching
                        ? null
                        : language.experienceSubtitle(level),
                    selected: (!widget.coaching ||
                            _viewModel.draft.experienceLevel != null) &&
                        _viewModel.selectedExperience == level,
                    onTap: () {
                      if (widget.coaching) {
                        chooseAnswer(() => _viewModel.selectExperience(level),
                            _onContinue);
                      } else {
                        _viewModel.selectExperience(level);
                      }
                    })),
        if (_part == 3 && !widget.coaching) ...[
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
    return OnboardingMonochrome(
        enabled: widget.coaching,
        child: Semantics(
            button: true,
            selected: selected,
            label: label,
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                    key: ValueKey('onboarding-gender-$gender'),
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      if (widget.coaching) {
                        chooseAnswer(
                            () => _viewModel.setGender(gender), _onContinue);
                      } else {
                        _viewModel.setGender(gender);
                      }
                    },
                    child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(children: [
                          Opacity(
                              opacity: selected ? 1 : .38,
                              child: SizedBox(
                                  height:
                                      ((MediaQuery.sizeOf(context).width - 80) /
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
                                      color: selected
                                          ? Colors.black
                                          : Colors.white))),
                        ]))))));
  }

  Widget _measurementSummary() {
    final language = _viewModel.selectedLanguage;
    return ValueListenableBuilder<int>(
        valueListenable: _viewModel.measurements,
        builder: (context, value, child) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoSlidingSegmentedControl<bool>(
                      key: const ValueKey('measurement-units'),
                      groupValue: _viewModel.isImperial,
                      backgroundColor: const Color(0xFF222225),
                      thumbColor: const Color(0xFF45454A),
                      padding: const EdgeInsets.all(4),
                      onValueChanged: (value) {
                        if (value != null) _viewModel.setImperial(value);
                      },
                      children: {
                        false: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            child: FitnessText(language.unitMetricLabel,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500))),
                        true: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            child: FitnessText(language.unitImperialLabel,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500))),
                      })),
              const SizedBox(height: 20),
              _measurementRow('age', language.ageLabel,
                  '${_viewModel.age} ${language.yearsUnit}'),
              _measurementRow('height', language.heightLabel,
                  '${_viewModel.heightDisplay} ${_viewModel.heightUnitDisplay ?? ''}'),
              _measurementRow('weight', language.weightLabel,
                  '${_viewModel.weightDisplay} ${_viewModel.weightUnitDisplay}'),
              _measurementRow('target', language.targetWeightLabel,
                  '${_viewModel.targetWeightDisplay} ${_viewModel.weightUnitDisplay}'),
            ]));
  }

  Widget _measurementRow(String metric, String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
          button: true,
          child: Material(
              color: const Color(0xFF232326),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                key: ValueKey('select-biometric-$metric'),
                borderRadius: BorderRadius.circular(24),
                onTap: _viewModel.controller.ready && !_advancing
                    ? () => _editMeasurement(metric)
                    : null,
                child: Container(
                    constraints: const BoxConstraints(minHeight: 72),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    child: LayoutBuilder(builder: (context, bounds) {
                      final stacked = bounds.maxWidth < 360 &&
                          MediaQuery.textScalerOf(context).scale(16) > 20;
                      final labelText = FitnessText(label,
                          style: const TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: Color(0xFFC7C7CC)));
                      final valueText = Text(value.trim(),
                          textAlign: stacked ? TextAlign.left : TextAlign.right,
                          style: const TextStyle(
                              fontSize: 18,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()]));
                      const arrow = Icon(Icons.chevron_right_rounded,
                          size: 19, color: Color(0xFF77777E));
                      if (stacked) {
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              labelText,
                              const SizedBox(height: 8),
                              Row(children: [
                                Expanded(child: valueText),
                                const SizedBox(width: 10),
                                arrow
                              ]),
                            ]);
                      }
                      return Row(children: [
                        Expanded(flex: 3, child: labelText),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: valueText),
                        const SizedBox(width: 10),
                        arrow
                      ]);
                    })),
              ))));

  Future<void> _editMeasurement(String metric) async {
    if (_editingMeasurement) return;
    _editingMeasurement = true;
    HapticFeedback.selectionClick();
    setState(() => _selectedMetric = metric);
    try {
      await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          backgroundColor: const Color(0xFF171719),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          builder: (sheetContext) => ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * .85),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: ValueListenableBuilder<int>(
                      valueListenable: _viewModel.measurements,
                      builder: (context, value, child) =>
                          Column(mainAxisSize: MainAxisSize.min, children: [
                            _ruler(plain: true),
                            const SizedBox(height: 24),
                            OnboardingContinueButton(
                                title: 'Done',
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop()),
                          ])))));
    } finally {
      _editingMeasurement = false;
    }
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

  Widget _ruler({bool plain = false}) {
    final model = _viewModel;
    final language = model.selectedLanguage;
    final imperial = model.isImperial;
    final rulerKey = ValueKey('ruler-$_selectedMetric-$imperial');

    if (_selectedMetric == 'age') {
      return BiometricRulerCard(
          plain: plain,
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
          plain: plain,
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
        plain: plain,
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
