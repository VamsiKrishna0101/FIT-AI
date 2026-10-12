import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/theme/fitness_theme.dart';
import 'onboarding_chrome.dart';

/// One scrollable content region and one reachable action across every step.
class OnboardingScaffold extends StatelessWidget {
  final int step, totalSteps;
  final String title, subtitle, actionTitle;
  final List<Widget> children;
  final VoidCallback? onBack, onContinue;
  final bool loading;
  final bool showProgress;
  final String? footer;
  const OnboardingScaffold(
      {super.key,
      required this.step,
      this.totalSteps = 8,
      required this.title,
      required this.subtitle,
      required this.actionTitle,
      required this.children,
      this.onBack,
      this.onContinue,
      this.loading = false,
      this.showProgress = true,
      this.footer});
  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
              statusBarColor: FitnessTheme.canvas,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: FitnessTheme.canvas,
              systemNavigationBarIconBrightness: Brightness.light),
          child: Scaffold(
            backgroundColor: FitnessTheme.canvas,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  if (showProgress)
                    OnboardingTopBar(
                        currentStep: step,
                        totalSteps: totalSteps,
                        onBack: onBack)
                  else
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: onBack == null
                                ? const SizedBox(height: 44)
                                : OnboardingBackButton(onPressed: onBack!))),
                  Expanded(
                      child: ListView(
                          key: const ValueKey('onboarding-scroll'),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          children: [
                        FitnessText(title,
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -.8,
                                height: 1.12)),
                        const SizedBox(height: 9),
                        FitnessText(subtitle,
                            style: const TextStyle(
                                fontSize: 14,
                                color: FitnessTheme.muted,
                                height: 1.45)),
                        const SizedBox(height: 24),
                        ...children
                      ])),
                  Container(
                      decoration: const BoxDecoration(
                          color: FitnessTheme.canvas,
                          border: Border(
                              top: BorderSide(color: Color(0x0FFFFFFF)))),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        LiquidChromeButton(
                            title: actionTitle,
                            onPressed: onContinue,
                            isLoading: loading),
                        if (footer != null &&
                            MediaQuery.viewInsetsOf(context).bottom == 0) ...[
                          const SizedBox(height: 10),
                          FitnessText(footer!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11, color: FitnessTheme.muted))
                        ],
                      ])),
                ])),
          )));
}

class OnboardingChoice extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  const OnboardingChoice(
      {super.key,
      required this.title,
      this.subtitle,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      selected: selected,
      child: Material(
          color: selected ? const Color(0xFF292929) : FitnessTheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                  color:
                      selected ? const Color(0xFFBCBCBC) : Colors.transparent,
                  width: .8)),
          child: InkWell(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        FitnessText(title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -.2)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 5),
                          FitnessText(subtitle!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: FitnessTheme.muted,
                                  height: 1.4))
                        ],
                      ])),
                  const SizedBox(width: 12),
                  Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                      color: selected
                          ? FitnessTheme.silver
                          : const Color(0xFF606060),
                      size: 20)
                ])),
          )));
}
