import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../models/workout_exercise_models.dart';
import 'exercise_thumbnail.dart';
import 'training_widgets.dart';

num? routineTargetWeight(TodayPlanItemModel item, int number) {
  final target = item.targetForSet(number);
  final weight =
      target == null ? item.targetWeight : target['weightKg'] as num?;
  return weight != null && weight > 0 ? weight : null;
}

/// A saved prescription: every set stays visible without logging controls.
class RoutineExerciseCard extends StatelessWidget {
  final TodayPlanItemModel item;
  final int number;
  final VoidCallback? onEdit;
  const RoutineExerciseCard(
      {super.key, required this.item, required this.number, this.onEdit});

  @override
  Widget build(BuildContext context) {
    String copy(String text, {Map<String, Object> values = const {}}) =>
        fitnessText(context, text, values: values);
    final format = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toLanguageTag())
      ..maximumFractionDigits = 4;
    num? load(int number) => routineTargetWeight(item, number);

    String reps(int number) {
      final target = item.targetForSet(number);
      if (target?['repsMin'] == null || target?['repsMax'] == null) {
        return item.targetReps.replaceAll('-', '–');
      }
      return target!['repsMin'] == target['repsMax']
          ? '${target['repsMax']}'
          : '${target['repsMin']}–${target['repsMax']}';
    }

    final showLoad = !item.isBodyweight ||
        List.generate(item.targetSets, (i) => load(i + 1))
            .any((weight) => weight != null && weight > 0);
    final unit = item.setTargets?['weightUnit'];
    final metadata = [
      copy('Rest: {seconds} sec', values: {'seconds': item.restSeconds}),
      if (item.isBodyweight) copy('Bodyweight'),
      if (showLoad && unit == 'per_hand') copy('Per hand'),
      if (showLoad && unit == 'total_load') copy('Total load'),
    ];
    Widget cell(String text, int flex, {bool heading = false}) => Expanded(
        flex: flex,
        child: Text(text,
            style: TextStyle(
                fontSize: heading ? 11 : 14,
                height: 1.4,
                color: heading ? DSColors.muted : DSColors.silver,
                fontWeight: heading ? FontWeight.w400 : FontWeight.w500)));

    return TrainingSurface(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ExerciseThumbnail(exercise: item.exercise, size: 56),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('$number. ${item.exercise.displayName}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          letterSpacing: -.2)),
                  const SizedBox(height: 4),
                  Text(metadata.join(' · '),
                      style: const TextStyle(
                          fontSize: 11, color: DSColors.muted, height: 1.5)),
                ])),
            if (onEdit != null)
              IconButton(
                  tooltip: copy('Edit targets'),
                  onPressed: onEdit,
                  icon: const Icon(CupertinoIcons.pencil,
                      size: 17, color: DSColors.silver)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            cell(copy('Set'), 1, heading: true),
            cell(copy('Reps'), 2, heading: true),
            if (showLoad) cell(copy('Target (kg)'), 2, heading: true),
          ]),
          const SizedBox(height: 4),
          for (var set = 1; set <= item.targetSets; set++)
            Semantics(
                key: ValueKey('routine-set-${item.id}-$set'),
                label: copy('Set {number}: {target}', values: {
                  'number': set,
                  'target': item.localizedTargetLabel(context, set) ?? ''
                }),
                excludeSemantics: true,
                child: Container(
                    constraints: const BoxConstraints(minHeight: 30),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: const BoxDecoration(
                        border: Border(
                            top:
                                BorderSide(color: DSColors.border, width: .5))),
                    child: Row(children: [
                      cell('$set', 1),
                      cell(reps(set), 2),
                      if (showLoad)
                        cell(load(set) == null ? '—' : format.format(load(set)),
                            2),
                    ]))),
        ]));
  }
}
