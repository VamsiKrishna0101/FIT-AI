import 'package:flutter/material.dart';
import '../../core/localization/fitness_text.dart';
import '../../core/theme/ds_colors.dart';

class MembershipBenefits extends StatelessWidget {
  const MembershipBenefits({super.key});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final item in const [
          (
            'Personalized weekly plans',
            'Exercises, sets, reps and weights adapted to your history.'
          ),
          (
            'Nutrition & recovery',
            'Food recommendations, logging and your daily readiness.'
          ),
          (
            'Your progress, over time',
            'Your workouts, saved routines and training history.'
          ),
        ])
          Container(
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: DSColors.border))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FitnessText(item.$1,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 7),
                    FitnessText(item.$2,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: DSColors.textSecondary)),
                  ])),
      ]);
}
