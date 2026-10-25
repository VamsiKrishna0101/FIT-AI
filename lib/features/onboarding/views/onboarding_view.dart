import '../viewmodels/onboarding_controller.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../components/onboarding_scaffold.dart';
import '../components/welcome_training_intro.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/branding/setcraft_brand.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import 'goal_selection_view.dart';
import '../../auth/views/auth_view.dart';
import '../../auth/auth_copy.dart';

class OnboardingView extends StatefulWidget {
  final OnboardingController? controller;
  const OnboardingView({super.key, this.controller});
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final OnboardingViewModel _viewModel;
  bool _saving = false;
  bool _artworkWarmed = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_artworkWarmed) return;
    _artworkWarmed = true;
    for (final sex in ['male', 'female']) {
      precacheImage(
          ResizeImage(AssetImage('assets/onboarding_bodies/$sex-front.png'),
              width: 500),
          context);
    }
  }

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
      // Persist the displayed default even when the language sheet was unused.
      _viewModel.draft.languageCode = _viewModel.selectedLanguage.code;
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
    return FitnessTheme(
        child: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Expanded(
                      child: ListView(padding: EdgeInsets.zero, children: [
                    Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                        child: Row(children: [
                          const SetcraftMark(size: 30),
                          const SizedBox(width: 10),
                          const Text('SETCRAFT',
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.4)),
                          const Spacer(),
                          TextButton(
                              key: const ValueKey('onboarding-language'),
                              onPressed:
                                  !_viewModel.ready ? null : _chooseLanguage,
                              child: Text(language.nativeName,
                                  style: const TextStyle(
                                      color: FitnessTheme.muted,
                                      fontSize: 12))),
                        ])),
                    const WelcomeTrainingIntro(),
                    const SizedBox(height: 24),
                  ])),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                      child: LiquidChromeButton(
                          title: 'Get started',
                          solid: true,
                          pill: true,
                          showArrow: false,
                          isLoading: _saving || !_viewModel.ready,
                          onPressed:
                              _saving || !_viewModel.ready ? null : _continue)),
                  TextButton(
                      onPressed: _saving
                          ? null
                          : () => OnboardingPageRoute<void>(
                                  page: const AuthView(initialSignIn: true))
                              .open(context),
                      child: FitnessText(
                          AuthCopy.forLanguage(language).switchToSignIn,
                          style: const TextStyle(
                              fontSize: 13, color: FitnessTheme.muted))),
                ]))));
  }

  Future<void> _chooseLanguage() => showModalBottomSheet<void>(
      context: context,
      backgroundColor: FitnessTheme.canvas,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
          child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * .75,
              child: ListView(padding: const EdgeInsets.all(24), children: [
                for (final option in AppLanguage.values)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OnboardingChoice(
                          title: option.nativeName,
                          selected: option == _viewModel.selectedLanguage,
                          onTap: () async {
                            await _viewModel.selectLanguage(option);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          })),
              ]))));
}
