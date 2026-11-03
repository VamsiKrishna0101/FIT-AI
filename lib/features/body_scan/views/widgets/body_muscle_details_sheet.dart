import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/fitness_copy.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../../train/components/exercise_recommendation_card.dart';
import '../../models/body_map_models.dart';
import '../../models/planned_physique_models.dart';
import 'body_controls.dart';

class BodyMuscleDetailsSheet extends StatefulWidget {
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
  State<BodyMuscleDetailsSheet> createState() => _BodyMuscleDetailsSheetState();
}

class _BodyMuscleDetailsSheetState extends State<BodyMuscleDetailsSheet> {
  late bool _recommended = !widget.trained;

  @override
  Widget build(BuildContext context) {
    final planned =
        <({PlannedPhysiqueDay day, List<PlannedPhysiqueExercise> exercises})>[
      for (final day in widget.workouts)
        if (!day.restDay)
          (
            day: day,
            exercises: day.exercises
                .where((exercise) =>
                    exercise.primary.contains(widget.id) ||
                    exercise.secondary.contains(widget.id))
                .toList()
          ),
    ]..removeWhere((group) => group.exercises.isEmpty);
    final logged = widget.region?.loggedExercises ?? <Map<String, dynamic>>[];
    final plannedSets = planned.fold(
        0,
        (sum, group) =>
            sum +
            group.exercises.fold(0, (sum, exercise) => sum + exercise.sets));
    final count = _recommended ? plannedSets : widget.region?.involvedSets ?? 0;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return FitnessTheme(
        child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                        child: Container(
                            width: 32,
                            height: 3,
                            decoration: BoxDecoration(
                                color: const Color(0xFF4C4F54),
                                borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 22),
                    Row(children: [
                      Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(14)),
                          child: Icon(CupertinoIcons.person,
                              size: 21, color: widget.accent)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            FitnessText(bodyRegionNames[widget.id] ?? widget.id,
                                style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -.6)),
                            const SizedBox(height: 4),
                            Text(widget.period,
                                style: const TextStyle(
                                    fontSize: 11, color: FitnessTheme.muted)),
                          ])),
                      IconButton(
                          tooltip: fitnessText(context, 'Close'),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF292C30)),
                          icon: const Icon(CupertinoIcons.xmark,
                              size: 13, color: FitnessTheme.silver)),
                    ]),
                    const SizedBox(height: 22),
                    BodySegment(
                        labels: const ['Logged', 'Recommended'],
                        selected: _recommended ? 1 : 0,
                        onChanged: (index) =>
                            setState(() => _recommended = index == 1)),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(
                          child: FitnessText(
                              _recommended
                                  ? 'Your weekly targets'
                                  : 'Your logged work',
                              style: const TextStyle(
                                  fontSize: 12, color: FitnessTheme.muted))),
                      FitnessText('{count} sets',
                          values: {'count': count},
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                    ]),
                    const SizedBox(height: 12),
                    Flexible(
                        child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_recommended)
                                  if (planned.isEmpty)
                                    _empty(
                                        CupertinoIcons.calendar,
                                        'No recommendations this week',
                                        'This muscle has no exercises in your saved weekly plan.')
                                  else
                                    for (final group in planned) ...[
                                      Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              2, 12, 2, 10),
                                          child: Row(children: [
                                            Expanded(
                                                child: Text(
                                                    DateFormat.MMMEd(locale)
                                                        .format(DateTime.parse(
                                                            group.day.date)),
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600))),
                                            if (group.day.status == 'COMPLETED')
                                              const Icon(
                                                  CupertinoIcons
                                                      .checkmark_circle,
                                                  size: 15,
                                                  color: FitnessTheme.silver),
                                          ])),
                                      for (final exercise in group.exercises)
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: ExerciseRecommendationCard(
                                              exercise:
                                                  exercise.toRecommendation(),
                                              onOpenExercise: () =>
                                                  Navigator.pop(
                                                      context,
                                                      BodyExerciseSelection(
                                                          exercise.exerciseId,
                                                          recommendation:
                                                              exercise,
                                                          date:
                                                              group.day.date)),
                                            )),
                                    ]
                                else if (widget.region == null)
                                  _empty(
                                      Icons.wifi_off_outlined,
                                      'Training data unavailable',
                                      'Close and refresh your Body screen.')
                                else if (logged.isEmpty)
                                  _empty(
                                      CupertinoIcons.chart_bar,
                                      'No logged exercises',
                                      'Your completed sets will appear here.')
                                else
                                  for (final exercise in logged)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Material(
                                          color: FitnessTheme.surface,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: InkWell(
                                            key: ValueKey(
                                                'body-muscle-exercise-${exercise['exerciseId']}'),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            onTap: () => Navigator.pop(
                                                context,
                                                BodyExerciseSelection(
                                                    '${exercise['exerciseId']}')),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Row(children: [
                                                  Expanded(
                                                      child: Text(
                                                          '${exercise['name'] ?? 'Exercise'}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  height:
                                                                      1.4))),
                                                  const SizedBox(width: 12),
                                                  FitnessText('{count} sets',
                                                      values: {
                                                        'count': ((exercise['directSets']
                                                                        as num?)
                                                                    ?.toInt() ??
                                                                0) +
                                                            ((exercise['assistingSets']
                                                                        as num?)
                                                                    ?.toInt() ??
                                                                0)
                                                      },
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: FitnessTheme
                                                              .muted)),
                                                  const SizedBox(width: 10),
                                                  const Icon(
                                                      CupertinoIcons
                                                          .chevron_right,
                                                      size: 12,
                                                      color:
                                                          FitnessTheme.muted),
                                                ])),
                                          ),
                                        )),
                              ])),
                    )),
                  ]),
            )));
  }

  Widget _empty(IconData icon, String title, String detail) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
      child: Column(children: [
        Icon(icon, color: FitnessTheme.muted, size: 28),
        const SizedBox(height: 14),
        FitnessText(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 7),
        FitnessText(detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12, color: FitnessTheme.muted, height: 1.5)),
      ]));
}
