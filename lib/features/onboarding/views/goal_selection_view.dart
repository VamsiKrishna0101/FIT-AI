import '../viewmodels/onboarding_controller.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/onboarding_page_route.dart';
import '../components/onboarding_scaffold.dart';
import '../models/working_toward_goal.dart';
import '../viewmodels/goal_viewmodel.dart';
import 'about_you_experience_view.dart';

// MARK: - Screen 01 — Your Goal (Apple Liquid Glass & 3D Metallic UI)
class GoalSelectionView extends StatefulWidget {
  final OnboardingController? controller;
  const GoalSelectionView({super.key, this.controller});

  @override
  State<GoalSelectionView> createState() => _GoalSelectionViewState();
}

class _GoalSelectionViewState extends State<GoalSelectionView> {
  bool _advancing = false;
  late final GoalViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GoalViewModel(controller: widget.controller)
      ..addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_rebuild);
    _viewModel.dispose();
    super.dispose();
  }

  void _onBack() {
    Navigator.of(context).pop();
  }

  Future<void> _onContinue() async {
    if (_advancing) return;
    setState(() => _advancing = true);
    try {
      await _viewModel.continueToNextStep();
      if (!mounted) return;
      await OnboardingPageRoute(
              page: AboutYouExperienceView(
                controller: _viewModel.controller,
                collectMeasurements: true,
              ))
          .open(context);
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    final selectedGoal = _viewModel.selectedGoal;

    return OnboardingScaffold(
      step: _viewModel.currentStep,
      sectionLabel: 'Your goals',
      totalSteps: _viewModel.totalSteps,
      title: language.headlineGoal,
      subtitle: language.subtitleGoal,
      actionTitle: language.continueButtonTitle,
      loading: _advancing,
      onBack: _onBack,
      onContinue: selectedGoal == null ? null : _onContinue,
      children: [
        for (final goal in const [
          WorkingTowardGoal.buildMuscle,
          WorkingTowardGoal.loseBodyFat,
          WorkingTowardGoal.getStronger,
          WorkingTowardGoal.getFitter,
          WorkingTowardGoal.buildConsistency
        ])
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OnboardingChoice(
                  title: language.goalTitle(goal),
                  selected: selectedGoal == goal,
                  onTap: () => _viewModel.selectGoal(goal))),
      ],
    );
  }
}
