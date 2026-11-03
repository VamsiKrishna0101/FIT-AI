import '../viewmodels/onboarding_controller.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';

import '../../../core/navigation/onboarding_page_route.dart';
import '../components/onboarding_scaffold.dart';
import '../components/training_hero.dart';
import '../viewmodels/schedule_location_viewmodel.dart';
import '../models/training_schedule_models.dart';
import 'equipment_selection_view.dart';

// MARK: - Combined Screen 04 & 05: Your Schedule & Space (Apple iOS Premium)
class ScheduleLocationView extends StatefulWidget {
  final OnboardingController? controller;
  final VoidCallback? onContinue;
  const ScheduleLocationView({super.key, this.controller, this.onContinue});

  @override
  State<ScheduleLocationView> createState() => _ScheduleLocationViewState();
}

class _ScheduleLocationViewState extends State<ScheduleLocationView> {
  bool _advancing = false;
  int _part = 0;
  late final ScheduleLocationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ScheduleLocationViewModel(controller: widget.controller)
      ..addListener(_rebuild);
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_rebuild);
    _viewModel.dispose();
    super.dispose();
  }

  void _onBack() {
    if (_part > 0) {
      setState(() => _part--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onContinue() async {
    if (_advancing) return;
    if (_part < 2) {
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
              page: EquipmentSelectionView(controller: _viewModel.controller))
          .open(context);
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    final valid = switch (_part) {
      0 => _viewModel.selectedDays != null,
      1 => _viewModel.selectedDuration != null,
      _ => _viewModel.selectedLocation != null,
    };
    return OnboardingScaffold(
      step: _viewModel.currentStep,
      totalSteps: _viewModel.totalSteps,
      sectionLabel: 'Your training',
      part: _part,
      parts: 3,
      canPop: _part == 0,
      title: switch (_part) {
        0 => language.weeklyCommitmentQuestion,
        1 => language.sessionDurationQuestion,
        _ => language.trainingLocationQuestion,
      },
      subtitle: switch (_part) {
        0 =>
          'Choose a week you can keep coming back to. You can change it later.',
        1 => 'We’ll use your available time to shape each session.',
        _ => 'Your plan will use the space and equipment you actually have.',
      },
      actionTitle: language.continueButtonTitle,
      loading: _advancing,
      onBack: _onBack,
      onContinue: _viewModel.controller.ready && valid ? _onContinue : null,
      children: [
        if (_part == 0)
          for (final option in DaysPerWeekOption.values)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OnboardingChoice(
                    title: fitnessText(context, '{count} days a week', values: {
                      'count': option.daysCount == 6 ? '6+' : option.daysCount
                    }),
                    selected: _viewModel.selectedDays == option,
                    onTap: () => _viewModel.selectDays(option))),
        if (_part == 0 && _viewModel.selectedDays != null) ...[
          const SizedBox(height: 10),
          const OnboardingContextNote(
              title: 'Consistency starts with a realistic week.',
              detail:
                  'Next, choose your session length and equipment. Together, these shape your plan.'),
        ],
        if (_part == 1)
          for (final option in WorkoutDurationOption.values)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OnboardingChoice(
                    title: language.durationOptionTitle(option),
                    selected: _viewModel.selectedDuration == option,
                    onTap: () => _viewModel.selectDuration(option))),
        if (_part == 2)
          for (final option in TrainingLocationOption.values)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OnboardingChoice(
                    title: language.locationOptionTitle(option),
                    selected: _viewModel.selectedLocation == option,
                    onTap: () => _viewModel.selectLocation(option))),
      ],
    );
  }
}
