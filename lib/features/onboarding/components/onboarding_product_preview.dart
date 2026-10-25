import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';
import 'onboarding_live_previews.dart';

/// A labelled product illustration, never a generated plan or a result forecast.
class OnboardingProductPreview extends StatelessWidget {
  const OnboardingProductPreview({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        decoration: BoxDecoration(
          color: FitnessTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: FitnessTheme.line),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Row(children: [
            Expanded(
                child: FitnessText('Your training',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            FitnessText('Preview',
                style: TextStyle(fontSize: 12, color: FitnessTheme.muted)),
          ]),
          const SizedBox(height: 20),
          const OnboardingMusclePreview(
              selected: {'chest', 'shoulders', 'triceps'}, height: 220),
          const SizedBox(height: 18),
          for (final label in [
            'Personalized weekly plans',
            'Nutrition & recovery',
            'Your progress, over time',
          ])
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: FitnessTheme.line))),
              child: FitnessText(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14)),
            ),
        ]),
      );
}
