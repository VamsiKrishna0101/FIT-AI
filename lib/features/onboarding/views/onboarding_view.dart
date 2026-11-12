import 'package:flutter/material.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../core/localization/fitness_text.dart';
import '../../auth/views/auth_view.dart';
import '../components/onboarding_scaffold.dart';
import '../components/welcome_training_intro.dart';
import '../components/welcome_coach_stage.dart';
import '../viewmodels/onboarding_controller.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../../../core/branding/setcraft_brand.dart';
import 'onboarding_journey.dart';

/// Mochi greets the user on a clean canvas, above one promise and one action.
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
      _viewModel.draft.languageCode = _viewModel.selectedLanguage.code;
      await _viewModel.continueToNextStep();
      if (mounted) {
        await OnboardingPageRoute(
                page: OnboardingJourney.start(_viewModel.controller))
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
          child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxHeight < 700 ||
            MediaQuery.textScalerOf(context).scale(16) > 20;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
                child: Center(
                    child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 488),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        const SetcraftWordmark(),
                        const Spacer(),
                        TextButton(
                            key: const ValueKey('onboarding-language'),
                            onPressed:
                                !_viewModel.ready ? null : _chooseLanguage,
                            style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFCCCCD0),
                                minimumSize: const Size(44, 44)),
                            child: Text(language.nativeName,
                                style: const TextStyle(fontSize: 11))),
                      ]),
                      const Spacer(),
                      Center(
                          child: WelcomeCoachStage(size: compact ? 104 : 160)),
                      const Spacer(),
                      SizedBox(height: compact ? 16 : 28),
                      WelcomeTrainingIntro(compact: compact),
                      SizedBox(height: compact ? 22 : 30),
                      LiquidChromeButton(
                          key: const ValueKey('welcome-get-started'),
                          title: 'Get started',
                          loadingTitle: 'Continuing…',
                          solid: true,
                          pill: true,
                          showArrow: false,
                          height: 54,
                          textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .1),
                          isLoading: _saving || !_viewModel.ready,
                          onPressed:
                              _saving || !_viewModel.ready ? null : _continue),
                      const SizedBox(height: 14),
                      TextButton(
                          key: const ValueKey('welcome-sign-in'),
                          onPressed: _saving
                              ? null
                              : () => OnboardingPageRoute<void>(
                                      page: const AuthView(initialSignIn: true))
                                  .open(context),
                          style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFA0A0AA),
                              minimumSize: const Size(48, 48)),
                          child: const FitnessText('Log in',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic))),
                    ]),
              ),
            ))),
          ),
        );
      })),
    ));
  }

  Future<void> _chooseLanguage() => showModalBottomSheet<void>(
      sheetAnimationStyle: DSMotion.sheetStyle(context),
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
