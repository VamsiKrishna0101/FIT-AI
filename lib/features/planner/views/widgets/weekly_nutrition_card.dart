import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/components/liquid_glass.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';

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
      return const FitnessCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(CupertinoIcons.person_crop_circle, color: Colors.white, size: 25),
        SizedBox(height: 14),
        FitnessText('Your daily targets',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        SizedBox(height: 7),
        FitnessText(
            'Complete your height, weight and profile in Body to personalize your daily intake.',
            style: TextStyle(
                fontSize: 12, color: FitnessTheme.muted, height: 1.5)),
      ]));
    }
    final protein = (values[0] as num).round();
    final carbs = (values[1] as num).round();
    final fat = (values[2] as num).round();
    return LiquidGlass(
      radius: 26,
      surfaceColor: const Color(0xFF191919),
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFF303030),
                  borderRadius: BorderRadius.circular(13)),
              child: const Icon(CupertinoIcons.flame,
                  size: 19, color: Colors.white)),
          const SizedBox(width: 12),
          const Expanded(
              child: FitnessText('Daily nutrition',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          const FitnessText('TARGET',
              style: TextStyle(
                  fontSize: 9, letterSpacing: 1.5, color: FitnessTheme.muted)),
        ]),
        const SizedBox(height: 24),
        Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 7, children: [
          Text('${(targets!['calories'] as num).round()}',
              style: const TextStyle(
                  fontSize: 42,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -1.8)),
          const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: FitnessText('kcal / day',
                  style: TextStyle(fontSize: 12, color: FitnessTheme.muted))),
        ]),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (context, box) {
          final wideText = MediaQuery.textScalerOf(context).scale(12) > 18;
          final cells = [
            _macro('Protein', protein, Colors.white),
            _macro('Carbs', carbs, const Color(0xFFC8C8C8)),
            _macro('Fat', fat, const Color(0xFF8F8F8F)),
          ];
          return wideText
              ? Wrap(spacing: 20, runSpacing: 16, children: cells)
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final cell in cells) Expanded(child: cell),
                ]);
        }),
        const SizedBox(height: 20),
        ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Row(children: [
              Expanded(
                  flex: (protein * 4).clamp(1, 100000).toInt(),
                  child: Container(height: 4, color: Colors.white)),
              const SizedBox(width: 3),
              Expanded(
                  flex: (carbs * 4).clamp(1, 100000).toInt(),
                  child: Container(height: 4, color: const Color(0xFFC8C8C8))),
              const SizedBox(width: 3),
              Expanded(
                  flex: (fat * 9).clamp(1, 100000).toInt(),
                  child: Container(height: 4, color: const Color(0xFF8F8F8F))),
            ])),
        const SizedBox(height: 13),
        const FitnessText('Starting estimates for your goal and activity.',
            style: TextStyle(
                fontSize: 11, color: FitnessTheme.muted, height: 1.4)),
      ]),
    );
  }

  Widget _macro(String name, int grams, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          FitnessText(name,
              style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
        ]),
        const SizedBox(height: 9),
        Text('$grams g',
            style: const TextStyle(
                fontSize: 23, fontWeight: FontWeight.w500, letterSpacing: -.5)),
      ]);
}
