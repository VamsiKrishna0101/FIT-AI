import '../../../core/localization/fitness_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fitness_theme.dart';
import 'onboarding_progress_bar.dart';
import '../../../core/branding/setcraft_brand.dart';

class OnboardingTopBar extends StatelessWidget {
  final int currentStep, totalSteps;
  final String sectionLabel;
  final VoidCallback? onBack;
  final int part, parts;
  const OnboardingTopBar(
      {super.key,
      required this.currentStep,
      required this.totalSteps,
      required this.sectionLabel,
      this.part = 0,
      this.parts = 1,
      this.onBack});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(children: [
            if (onBack != null)
              OnboardingBackButton(onPressed: onBack!)
            else
              const SetcraftMark(),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Semantics(
                      label: fitnessText(context, 'Step {step} of {total}',
                          values: {'step': currentStep, 'total': totalSteps}),
                      child: ExcludeSemantics(
                          child: OnboardingProgressBar(
                              currentStep: currentStep,
                              totalSteps: totalSteps,
                              progress: ((currentStep - 1) + part / parts) /
                                  totalSteps))),
                ])),
          ])));
}

class OnboardingBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const OnboardingBackButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          icon: const Icon(Icons.chevron_left_rounded,
              size: 24, color: FitnessTheme.silver)));
}
