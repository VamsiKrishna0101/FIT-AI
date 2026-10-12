import 'package:flutter/material.dart';

import '../../../core/navigation/onboarding_page_route.dart';
import '../components/onboarding_scaffold.dart';
import '../models/working_toward_goal.dart';
import '../viewmodels/goal_viewmodel.dart';
import 'about_you_experience_view.dart';

// MARK: - Screen 01 — Your Goal (Apple Liquid Glass & 3D Metallic UI)
class GoalSelectionView extends StatefulWidget {
  const GoalSelectionView({super.key});

  @override
  State<GoalSelectionView> createState() => _GoalSelectionViewState();
}

class _GoalSelectionViewState extends State<GoalSelectionView> {
  late final GoalViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GoalViewModel()..addListener(_rebuild);
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

  void _onContinue() async {
    await _viewModel.continueToNextStep();
    if (!mounted) return;
    Navigator.of(context).push(
      OnboardingPageRoute(page: const AboutYouExperienceView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    final selectedGoal = _viewModel.selectedGoal;

    return OnboardingScaffold(
      step: _viewModel.currentStep,
      totalSteps: _viewModel.totalSteps,
      title: language.headlineGoal,
      subtitle: language.subtitleGoal,
      actionTitle: language.continueButtonTitle,
      onBack: _onBack,
      onContinue: selectedGoal == null ? null : _onContinue,
      children: [
        for (final goal in WorkingTowardGoal.values)
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OnboardingChoice(
                  title: language.goalTitle(goal),
                  subtitle: language.goalSubtitle(goal),
                  selected: selectedGoal == goal,
                  onTap: () => _viewModel.selectGoal(goal))),
      ],
    );
  }
}
