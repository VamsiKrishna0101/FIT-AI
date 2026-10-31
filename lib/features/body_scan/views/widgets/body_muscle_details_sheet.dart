import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_copy.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_map_models.dart';
import '../../models/planned_physique_models.dart';
import 'body_controls.dart';

class BodyMuscleDetailsSheet extends StatelessWidget {
  final String id, period;
  final BodyMapRegion? region;
  final bool trained;
  final Color accent;
  final List<PlannedPhysiqueDay> workouts;
  const BodyMuscleDetailsSheet(
      {super.key,
      required this.id,
      required this.region,
      required this.trained,
      required this.period,
      required this.workouts,
      this.accent = FitnessTheme.silver});

  @override
  Widget build(BuildContext context) {
    final rows = <String, ({String name, int sets})>{};
    void add(String exerciseId, String name, int sets) {
      if (exerciseId.isEmpty) return;
      rows[exerciseId] =
          (name: name, sets: (rows[exerciseId]?.sets ?? 0) + sets);
    }

    if (trained) {
      for (final exercise
          in region?.loggedExercises ?? <Map<String, dynamic>>[]) {
        add(
            exercise['exerciseId'] as String? ?? '',
            exercise['name'] as String? ?? '',
            (exercise['directSets'] as num? ?? 0).toInt() +
                (exercise['assistingSets'] as num? ?? 0).toInt());
      }
    } else {
      for (final day in workouts) {
        for (final exercise in day.exercises) {
          if (exercise.primary.contains(id) ||
              exercise.secondary.contains(id)) {
            add(exercise.exerciseId, exercise.name, exercise.sets);
          }
        }
      }
    }
    final count = trained
        ? region?.involvedSets ?? 0
        : rows.values.fold(0, (sum, row) => sum + row.sets);
    return FitnessTheme(
        child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                        child: Container(
                            width: 30,
                            height: 3,
                            decoration: BoxDecoration(
                                color: const Color(0xFF4C4F54),
                                borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 18),
                    Row(children: [
                      Container(
                          width: 3,
                          height: 28,
                          decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            FitnessText(bodyRegionNames[id] ?? id,
                                style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -.4)),
                            const SizedBox(height: 5),
                            Text(period,
                                style: const TextStyle(
                                    fontSize: 11, color: FitnessTheme.muted)),
                          ])),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$count',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -.5)),
                            const FitnessText('sets',
                                style: TextStyle(
                                    fontSize: 10, color: FitnessTheme.muted)),
                          ]),
                      const SizedBox(width: 10),
                      IconButton(
                          tooltip: fitnessText(context, 'Close'),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF292C30),
                              minimumSize: const Size(40, 40),
                              maximumSize: const Size(40, 40)),
                          icon: const Icon(CupertinoIcons.xmark,
                              size: 13, color: FitnessTheme.silver)),
                    ]),
                    const SizedBox(height: 18),
                    const Divider(
                        height: 1, thickness: .5, color: Color(0x18FFFFFF)),
                    ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * .52),
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              if (region == null)
                                const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: FitnessText(
                                        'Training data is unavailable. Please retry.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: FitnessTheme.muted)))
                              else if (rows.isEmpty)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24),
                                    child: FitnessText(
                                        trained
                                            ? 'No exercises logged for these dates.'
                                            : 'No exercises planned for this muscle.',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: FitnessTheme.muted)))
                              else
                                for (final row in rows.entries)
                                  Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        key: ValueKey(
                                            'body-muscle-exercise-${row.key}'),
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () =>
                                            Navigator.pop(context, row.key),
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            child: Row(children: [
                                              Expanded(
                                                  child: Text(row.value.name,
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          height: 1.35))),
                                              const SizedBox(width: 16),
                                              FitnessText('{count} sets',
                                                  values: {
                                                    'count': row.value.sets
                                                  },
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          FitnessTheme.muted)),
                                              const SizedBox(width: 10),
                                              const Icon(
                                                  CupertinoIcons.chevron_right,
                                                  size: 12,
                                                  color: FitnessTheme.muted),
                                            ])),
                                      )),
                            ]))),
                  ]),
            )));
  }
}
