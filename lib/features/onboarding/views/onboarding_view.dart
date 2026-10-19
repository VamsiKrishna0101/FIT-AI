import '../viewmodels/onboarding_controller.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../components/onboarding_scaffold.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import 'goal_selection_view.dart';

class OnboardingView extends StatefulWidget {
  final OnboardingController? controller;
  const OnboardingView({super.key, this.controller});
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final OnboardingViewModel _viewModel;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingViewModel(controller: widget.controller)
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

  Future<void> _continue() async {
    if (_saving || !_viewModel.ready) return;
    setState(() => _saving = true);
    try {
      await _viewModel.continueToNextStep();
      if (mounted) {
        await OnboardingPageRoute(
                page: GoalSelectionView(controller: _viewModel.controller))
            .open(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = _viewModel.selectedLanguage;
    return OnboardingScaffold(
      step: 1,
      title: language.headline,
      subtitle: 'Choose the language you feel at home in.',
      actionTitle: language.continueButtonTitle,
      onContinue: _saving || !_viewModel.ready ? null : _continue,
      loading: _saving || !_viewModel.ready,
      footer: language.settingsNote,
      children: [
        for (final option in AppLanguage.values)
          Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: OnboardingChoice(
                  title: option.nativeName,
                  selected: option == language,
                  onTap: () => _viewModel.selectLanguage(option)))
      ],
    );
  }
}
