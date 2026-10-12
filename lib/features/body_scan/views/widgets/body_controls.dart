import '../../../../core/localization/language_manager.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/fitness_theme.dart';

const bodyRegionNames = {
  'chest': 'Chest',
  'shoulders': 'Shoulders',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'forearms': 'Forearms',
  'upper_back': 'Upper back',
  'lats': 'Lats',
  'lower_back': 'Lower back',
  'core': 'Core',
  'glutes': 'Hips & glutes',
  'quads': 'Quads',
  'hamstrings': 'Hamstrings',
  'calves': 'Calves',
};
String bodyDate(String date) =>
    DateFormat('MMM d, y', LanguageManager.shared.currentLanguage.code)
        .format(DateTime.parse(date));

class BodySegment extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const BodySegment(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: const Color(0xFF292929),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
                child: Semantics(
              selected: i == selected,
              button: true,
              child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: Container(
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
                    decoration: BoxDecoration(
                        color: selected == i
                            ? const Color(0xFF484848)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9)),
                    child: FitnessText(
                        labels[i] == 'Back'
                            ? 'Back view'
                            : labels[i] == 'Front'
                                ? 'Front view'
                                : labels[i],
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected == i
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected == i
                                ? Colors.white
                                : FitnessTheme.muted)),
                  )),
            ))
        ]),
      );
}

class BodySectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const BodySectionTitle(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(children: [
        Expanded(
            child: FitnessText(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.25))),
        if (action != null)
          TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(40, 32),
                  foregroundColor: FitnessTheme.muted),
              child:
                  FitnessText(action!, style: const TextStyle(fontSize: 12))),
      ]));
}

class BodyLegend extends StatelessWidget {
  final Color color;
  final String label;
  const BodyLegend(this.color, this.label, {super.key});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        FitnessText(label,
            style: const TextStyle(fontSize: 11, color: FitnessTheme.muted)),
      ]);
}
