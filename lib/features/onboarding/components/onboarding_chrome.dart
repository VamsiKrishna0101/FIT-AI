import '../../../core/localization/fitness_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Quiet brand header; progress remains available to assistive technology.
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
              width: 44,
              child: onBack == null
                  ? null
                  : OnboardingBackButton(onPressed: onBack!)),
          Expanded(
              child: Semantics(
            label: fitnessText(context, 'Step {step} of {total}',
                values: {'step': currentStep, 'total': totalSteps}),
            child: const ExcludeSemantics(
                child: Text('SETCRAFT',
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -.8,
                        color: Color(0xFF606066)))),
          )),
          const SizedBox(width: 44, height: 56),
        ]),
      );
}

class OnboardingBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const OnboardingBackButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 44,
        child: IconButton(
          style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF19191B),
              foregroundColor: const Color(0xFFDDDDDD)),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          icon: const Icon(Icons.chevron_left_rounded, size: 24),
        ),
      );
}
