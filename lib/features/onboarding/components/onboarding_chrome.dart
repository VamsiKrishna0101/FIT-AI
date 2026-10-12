import '../../../core/localization/fitness_copy.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/fitness_theme.dart';
import 'onboarding_progress_bar.dart';

class OnboardingTopBar extends StatelessWidget {
  final int currentStep, totalSteps;
  final VoidCallback? onBack;
  const OnboardingTopBar(
      {super.key,
      required this.currentStep,
      required this.totalSteps,
      this.onBack});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SizedBox(
          height: 44,
          child: Row(children: [
            if (onBack != null)
              OnboardingBackButton(onPressed: onBack!)
            else
              const SizedBox(width: 44),
            const SizedBox(width: 14),
            Expanded(
                child: Semantics(
                    label: fitnessText(context, 'Step {step} of {total}',
                        values: {'step': currentStep, 'total': totalSteps}),
                    child: OnboardingProgressBar(
                        currentStep: currentStep, totalSteps: totalSteps))),
            const SizedBox(width: 14),
            FitnessText('$currentStep / $totalSteps',
                style:
                    const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
          ])));
}

class OnboardingBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const OnboardingBackButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 44,
      height: 44,
      child: IconButton.filledTonal(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          style: IconButton.styleFrom(backgroundColor: FitnessTheme.surface),
          onPressed: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          icon: const Icon(Icons.chevron_left_rounded,
              size: 24, color: FitnessTheme.silver)));
}
