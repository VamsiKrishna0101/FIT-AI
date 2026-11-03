import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../../train/components/training_widgets.dart';

class WeeklyNutritionCard extends StatelessWidget {
  final Map? targets;
  const WeeklyNutritionCard({super.key, required this.targets});

  @override
  Widget build(BuildContext context) {
    final values = [targets?['protein'], targets?['carbs'], targets?['fat']];
    final available = targets?['calories'] is num &&
        (targets!['calories'] as num) > 0 &&
        values.every((v) => v is num && v > 0);
    if (!available) {
      return const TrainingSurface(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FitnessText('Your daily targets',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        FitnessText(
            'Complete your height, weight and profile in Body to personalize your daily intake.',
            style: TextStyle(
                fontSize: 12, color: FitnessTheme.muted, height: 1.5)),
      ]));
    }
    return TrainingSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const FitnessText('Daily nutrition',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w500, letterSpacing: -.3)),
        const SizedBox(height: 12),
        Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 7,
            children: [
              Text('${(targets!['calories'] as num).round()}',
                  style: const TextStyle(
                      fontSize: 23,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.5)),
              const FitnessText('kcal / day',
                  style: TextStyle(fontSize: 12, color: FitnessTheme.muted)),
            ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12)),
          child: LayoutBuilder(builder: (context, bounds) {
            final columns =
                MediaQuery.textScalerOf(context).scale(12) > 18 ? 1 : 3;
            final width = (bounds.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(spacing: 12, runSpacing: 14, children: [
              for (var i = 0; i < values.length; i++)
                SizedBox(
                    width: width,
                    child: _macro(['Protein', 'Carbs', 'Fat'][i],
                        (values[i] as num).round())),
            ]);
          }),
        ),
        const SizedBox(height: 12),
        const FitnessText('Starting estimates for your goal and activity.',
            style: TextStyle(
                fontSize: 11, color: FitnessTheme.muted, height: 1.4)),
      ]),
    );
  }

  Widget _macro(String label, int grams) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FitnessText(label,
            style: const TextStyle(
                fontSize: 11, color: FitnessTheme.muted, height: 1.4)),
        const SizedBox(height: 6),
        Text('$grams g',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: -.3)),
      ]);
}
