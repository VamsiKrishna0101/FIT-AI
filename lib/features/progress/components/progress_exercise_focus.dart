import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';

/// A compact preview; the full chart and records live on the detail screen.
class ProgressExerciseFocus extends StatefulWidget {
  final List<ProgressJson> exercises;
  final List<String> pins;
  final ValueChanged<ProgressJson> onOpen;
  const ProgressExerciseFocus({
    super.key,
    required this.exercises,
    required this.onOpen,
    this.pins = const [],
  });

  @override
  State<ProgressExerciseFocus> createState() => _ProgressExerciseFocusState();
}

class _ProgressExerciseFocusState extends State<ProgressExerciseFocus> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final exercises = widget.exercises
        .where((row) =>
            row['id'] is String &&
            (row['latest'] is Map ||
                ProgressPoint.parse(progressRows(row['sparkline']), 'value')
                    .isNotEmpty))
        .toList();
    if (exercises.isEmpty) {
      return const ProgressSurface(
          child: ProgressEmpty('Log sets to see how your exercises improve.'));
    }
    final exercise = exercises
            .where((row) => row['id'] == _selected)
            .firstOrNull ??
        exercises.where((row) => widget.pins.contains(row['id'])).firstOrNull ??
        exercises.first;
    final id = exercise['id'] as String;
    final latest = exercise['latest'] as Map?;
    final load = progressNumber(latest?['weight']);
    final isLoad = exercise['metric'] == 'load' ||
        (exercise['metric'] == null && load != null && load > 0);
    final points =
        ProgressPoint.parse(progressRows(exercise['sparkline']), 'value');
    final value = points.lastOrNull?.value ??
        (isLoad ? load : progressNumber(latest?['reps']));
    final unit = isLoad ? 'kg' : 'reps';
    final change = isLoad ? progressNumber(exercise['change']) : null;
    final sessions = progressNumber(exercise['sessions']);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ProgressSurface(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: exercises.length > 1
              ? DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const ValueKey('progress-featured-exercise'),
                    value: id,
                    isExpanded: true,
                    itemHeight: null,
                    menuMaxHeight: MediaQuery.sizeOf(context).height * .5,
                    dropdownColor: progressCard,
                    borderRadius: BorderRadius.circular(14),
                    icon: const Icon(CupertinoIcons.chevron_down,
                        size: 12, color: progressMuted),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: progressSilver),
                    items: [
                      for (final row in exercises)
                        DropdownMenuItem(
                            value: row['id'] as String,
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                    progressTitle(row['name'] as String? ?? ''),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (value) => setState(() => _selected = value),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(progressTitle(exercise['name'] as String? ?? ''),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600))),
        ),
        Semantics(
          button: true,
          label: fitnessText(context, 'Details'),
          child: InkWell(
            key: const ValueKey('progress-featured-details'),
            onTap: () => widget.onOpen(exercise),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  fitnessText(
                                      context, isLoad ? 'Best weight' : 'Reps'),
                                  style: const TextStyle(
                                      fontSize: 11, color: progressMuted)),
                              const SizedBox(height: 5),
                              ProgressValueText(
                                  progressValue(context, value, unit: unit),
                                  size: 27),
                            ]),
                      ),
                      if (change != null && change.isFinite) ...[
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    '${change > 0 ? '+' : ''}${progressValue(context, change)}%',
                                    key: const ValueKey(
                                        'progress-exercise-change'),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                    fitnessText(
                                        context, 'Change in this period'),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                        fontSize: 11, color: progressMuted)),
                              ]),
                        ),
                      ],
                      const SizedBox(width: 10),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 12, color: progressMuted),
                    ]),
                    const SizedBox(height: 12),
                    if (points.length >= 2) ...[
                      Semantics(
                        label:
                            '${fitnessText(context, isLoad ? 'Best weight' : 'Reps')}: '
                            '${progressValue(context, points.first.value, unit: unit)} – '
                            '${progressValue(context, points.last.value, unit: unit)}',
                        child: SizedBox(
                            height: 46,
                            width: double.infinity,
                            child: ProgressSparkline(
                                points: points, color: progressCyan)),
                      ),
                      const SizedBox(height: 7),
                      Row(children: [
                        Expanded(
                            child: Text(
                                progressDate(
                                    points.first.date.toIso8601String(),
                                    locale),
                                style: const TextStyle(
                                    fontSize: 11, color: progressMuted))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                progressDate(
                                    points.last.date.toIso8601String(), locale),
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    fontSize: 11, color: progressMuted))),
                      ]),
                    ] else
                      Text(
                          fitnessText(
                              context, 'More workouts will reveal your trend.'),
                          style: const TextStyle(
                              fontSize: 12, color: progressMuted, height: 1.4)),
                    if (points.length >= 12 &&
                        sessions != null &&
                        sessions > points.length) ...[
                      const SizedBox(height: 7),
                      Text(
                          fitnessText(
                              context, '{count} recent sessions', values: {
                            'count':
                                progressValue(context, points.length, digits: 0)
                          }),
                          style: const TextStyle(
                              fontSize: 11, color: progressMuted)),
                    ],
                  ]),
            ),
          ),
        ),
      ]),
    );
  }
}
