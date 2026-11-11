import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_motion.dart';
import '../models/workout_exercise_models.dart';
import 'planned_exercise_row.dart';
import 'training_widgets.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';

/// Informational preparation is deliberately separate from the working-set logger.
class WorkoutWarmup extends StatelessWidget {
  final Map<String, dynamic>? warmup;
  final bool compact;
  final Future<WorkoutExerciseModel?> Function(String)? loadExercise;
  final bool isCompleted;
  final VoidCallback? onComplete;

  const WorkoutWarmup(
      {super.key,
      required this.warmup,
      this.compact = false,
      this.loadExercise,
      this.isCompleted = false,
      this.onComplete});

  @override
  Widget build(BuildContext context) {
    final steps = (warmup?['steps'] as List? ?? []).whereType<Map>().toList();
    if (steps.isEmpty) return const SizedBox.shrink();
    if (compact) return _compact(context, steps);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FitnessCard(
          padding: EdgeInsets.zero,
          child: Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                key: const ValueKey('workout-warmup'),
                initiallyExpanded: !isCompleted,
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                title: Row(
                  children: [
                    const FitnessText('Warm-up',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.checkmark_alt,
                                size: 12, color: Color(0xFF22C55E)),
                            SizedBox(width: 4),
                            FitnessText('Completed',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF22C55E))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: FitnessText(
                    'About {minutes} min · before working sets',
                    values: {'minutes': warmup?['durationMinutes'] ?? 5},
                    style: const TextStyle(
                        fontSize: 12, color: FitnessTheme.muted)),
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FitnessText('${i + 1}. ${steps[i]['name']}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 5),
                              if (steps[i]['reps'] != null)
                                FitnessText('{reps} practice reps',
                                    values: {'reps': steps[i]['reps']},
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.silver)),
                              if ((steps[i]['weightKg'] as num?) != null)
                                FitnessText(
                                    '{weight} kg · lighter than working load',
                                    values: {'weight': steps[i]['weightKg']},
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.muted)),
                              FitnessText('${steps[i]['instruction']}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: FitnessTheme.muted,
                                      height: 1.45)),
                            ])),
                  FitnessText('${warmup?['note'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: FitnessTheme.muted,
                          height: 1.45)),
                  if (!isCompleted && onComplete != null) ...[
                    const SizedBox(height: 14),
                    TrainingButton(
                      label: 'Complete Warm-up',
                      primary: true,
                      onPressed: onComplete,
                    ),
                  ],
                ],
              ))),
    );
  }

  Widget _compact(BuildContext context, List<Map> steps) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TrainingSurface(
          onTap: () => _showSteps(context, steps),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    children: [
                      const FitnessText('Warm-up',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      if (isCompleted) ...[
                        const SizedBox(width: 6),
                        const Icon(CupertinoIcons.checkmark_alt_circle_fill,
                            size: 14, color: Color(0xFF22C55E)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  FitnessText('{count} steps',
                      values: {'count': steps.length},
                      style: const TextStyle(
                          fontSize: 11, color: FitnessTheme.muted)),
                ])),
            FitnessText('About {minutes} min',
                values: {'minutes': warmup?['durationMinutes'] ?? 5},
                style:
                    const TextStyle(fontSize: 12, color: FitnessTheme.muted)),
            const SizedBox(width: 12),
            const Icon(CupertinoIcons.chevron_right,
                size: 12, color: FitnessTheme.muted),
          ]),
        ),
      );

  String _stepSummary(BuildContext context, Map step) => [
        if (step['reps'] != null)
          fitnessText(context, '{reps} practice reps',
              values: {'reps': step['reps']}),
        if (step['weightKg'] case final num weight when weight > 0)
          '$weight kg',
        if (step['seconds'] case final num seconds when seconds > 0)
          seconds % 60 == 0
              ? '${seconds ~/ 60} ${fitnessText(context, 'min')}'
              : '${seconds.round()} s',
      ].join(' · ');

  Future<void> _showSteps(BuildContext context, List<Map> steps) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: FitnessTheme.canvas,
        constraints: BoxConstraints(
            maxWidth: 560, maxHeight: MediaQuery.sizeOf(context).height * .88),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        clipBehavior: Clip.antiAlias,
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        builder: (context) => FitnessTheme(
            child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          const Expanded(
                              child: FitnessText('Warm-up',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600))),
                          IconButton(
                              tooltip: fitnessText(context, 'Close'),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(CupertinoIcons.xmark, size: 17)),
                        ]),
                        FitnessText('About {minutes} min · before working sets',
                            values: {
                              'minutes': warmup?['durationMinutes'] ?? 5
                            },
                            style: const TextStyle(
                                fontSize: 12, color: FitnessTheme.muted)),
                        const SizedBox(height: 16),
                        Flexible(
                            child: SingleChildScrollView(
                                child: Column(children: [
                          for (var i = 0; i < steps.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            TrainingSurface(
                                padding: EdgeInsets.zero,
                                child: Column(children: [
                                  if ('${steps[i]['exerciseId'] ?? ''}'
                                      .isNotEmpty)
                                    PlannedExerciseRow(
                                      key: ValueKey('warmup-exercise-$i'),
                                      exercise:
                                          Map<String, dynamic>.from(steps[i]),
                                      summary: _stepSummary(context, steps[i]),
                                      showPrescription: false,
                                      loadExercise: loadExercise,
                                    )
                                  else
                                    Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(children: [
                                          Text('${i + 1}'.padLeft(2, '0'),
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: FitnessTheme.muted)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                FitnessText(
                                                    '${steps[i]['name']}',
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500)),
                                                const SizedBox(height: 5),
                                                Text(
                                                    _stepSummary(
                                                        context, steps[i]),
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: FitnessTheme
                                                            .muted)),
                                              ])),
                                        ])),
                                  if ('${steps[i]['instruction'] ?? ''}'
                                      .trim()
                                      .isNotEmpty)
                                    ExpansionTile(
                                      key: ValueKey('warmup-instructions-$i'),
                                      shape: const Border(),
                                      collapsedShape: const Border(),
                                      tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      childrenPadding:
                                          const EdgeInsets.fromLTRB(
                                              14, 0, 14, 14),
                                      title: const FitnessText('Instructions',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: FitnessTheme.muted)),
                                      children: [
                                        FitnessText(
                                            '${steps[i]['instruction']}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                height: 1.5,
                                                color: FitnessTheme.silver))
                                      ],
                                    ),
                                ])),
                          ],
                          if ('${warmup?['note'] ?? ''}'.trim().isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: ExpansionTile(
                                  shape: const Border(),
                                  collapsedShape: const Border(),
                                  tilePadding: EdgeInsets.zero,
                                  title: const FitnessText('Before you begin',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: FitnessTheme.muted)),
                                  children: [
                                    FitnessText('${warmup!['note']}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.5,
                                            color: FitnessTheme.muted))
                                  ],
                                )),
                        ]))),
                        const SizedBox(height: 14),
                        TrainingButton(
                            label: isCompleted ? 'Done' : 'Complete Warm-up',
                            primary: true,
                            onPressed: () {
                              Navigator.pop(context);
                              if (!isCompleted) {
                                onComplete?.call();
                              }
                            }),
                      ]),
                ))),
      );
}
