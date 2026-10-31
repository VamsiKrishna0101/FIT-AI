import 'package:flutter/material.dart';
import '../../../core/components/motion.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';
import 'progress_weekly_bars.dart';

class MuscleDistributionContent extends StatefulWidget {
  final List<ProgressJson> muscles;
  final ValueChanged<ProgressJson> onMuscle;
  const MuscleDistributionContent(
      {super.key, required this.muscles, required this.onMuscle});
  @override
  State<MuscleDistributionContent> createState() =>
      _MuscleDistributionContentState();
}

class _MuscleDistributionContentState extends State<MuscleDistributionContent> {
  String _metric = 'directSets';
  @override
  Widget build(BuildContext context) {
    final rows = [...widget.muscles]..sort((a, b) =>
        (progressNumber(b[_metric]) ?? 0)
            .compareTo(progressNumber(a[_metric]) ?? 0));
    final maximum = rows.fold<double>(
        1,
        (max, row) => (progressNumber(row[_metric]) ?? 0) > max
            ? progressNumber(row[_metric])!
            : max);
    final trained = rows
        .where((row) =>
            (progressNumber(row['directSets']) ?? 0) > 0 ||
            (progressNumber(row['assistingSets']) ?? 0) > 0)
        .length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProgressSurface(
          accent: progressMuscle,
          child: Row(children: [
            Expanded(
                child: Text(fitnessText(context, 'Muscles trained'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500))),
            Text(progressValue(context, trained, digits: 0),
                style:
                    const TextStyle(fontSize: 34, fontWeight: FontWeight.w600)),
          ])),
      const ProgressNote(
          'Logged exposure describes training, not measured muscle growth.'),
      ProgressMetricPicker(
          choices: const {
            'directSets': 'Direct sets',
            'assistingSets': 'Assisting sets'
          },
          selected: _metric,
          color: progressMuscle,
          onChanged: (value) => setState(() => _metric = value)),
      const SizedBox(height: 16),
      ProgressSurface(
          child: Column(children: [
        if (rows.isEmpty)
          const ProgressEmpty(
              'Log sets to build your muscle training history.'),
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const Divider(height: 18, color: DSColors.border),
          _row(context, rows[index], maximum),
        ],
      ])),
      const ProgressNote(
          'Direct sets target this muscle. Assisting sets use it as a secondary muscle.'),
    ]);
  }

  Widget _row(BuildContext context, ProgressJson row, double maximum) {
    final value = progressNumber(row[_metric]) ?? 0;
    final color = progressMuscleColor(row['id'] as String? ?? '');
    return InkWell(
        onTap: () => widget.onMuscle(row),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: Text(progressMuscleLabel(context, row),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500))),
                const SizedBox(width: 12),
                Text(progressValue(context, value, digits: 0),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: progressSilver)),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right, size: 17, color: progressMuted),
              ]),
              const SizedBox(height: 11),
              ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: MotionValue(
                      value: value / maximum,
                      builder: (context, animated) => LinearProgressIndicator(
                          value: animated,
                          minHeight: 8,
                          color: color,
                          backgroundColor: DSColors.bgRaised))),
            ])));
  }
}

class MuscleProgressContent extends StatelessWidget {
  final ProgressJson data;
  final ValueChanged<ProgressJson> onExercise;
  const MuscleProgressContent(
      {super.key, required this.data, required this.onExercise});
  @override
  Widget build(BuildContext context) {
    final muscle = data['muscle'] as Map? ?? {};
    final color = progressMuscleColor(muscle['id'] as String? ?? '');
    final points = ProgressPoint.parse(progressRows(data['weeks']), 'sets');
    final exercises = progressRows(data['exercises']);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProgressFactGrid(color: color, facts: [
        (
          'Direct sets',
          progressValue(context, progressNumber(muscle['directSets']),
              digits: 0)
        ),
        (
          'Assisting sets',
          progressValue(context, progressNumber(muscle['assistingSets']),
              digits: 0)
        ),
        (
          'Training days',
          progressValue(context, progressNumber(muscle['trainingDays']),
              digits: 0)
        ),
      ]),
      const SizedBox(height: 16),
      ProgressSurface(
          accent: color,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fitnessText(context, 'Direct sets'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
                '${fitnessText(context, 'Last trained')} · '
                '${progressDate(muscle['lastTrained'] as String?, Localizations.localeOf(context).toLanguageTag())}',
                style: const TextStyle(fontSize: 13, color: progressMuted)),
            const SizedBox(height: 20),
            if (points.isEmpty)
              const ProgressEmpty('No sets in this period')
            else if (points.length <= 6)
              ProgressWeeklyBars(
                  points: points, metric: 'Direct sets', color: color)
            else
              ProgressChart(
                  points: points,
                  unit: 'sets',
                  bars: true,
                  color: color,
                  height: 145,
                  showReadings: true),
          ])),
      const ProgressNote(
          'Direct sets target this muscle. Assisting sets use it as a secondary muscle.'),
      const ProgressHeading('Exercises'),
      ProgressSurface(
          child: exercises.isEmpty
              ? const ProgressEmpty('No logged exercises found')
              : Column(children: [
                  for (var i = 0; i < exercises.length; i++) ...[
                    if (i > 0)
                      const Divider(color: DSColors.border, height: 16),
                    ProgressExerciseRow(
                        exercise: exercises[i],
                        onTap: () => onExercise(exercises[i])),
                  ],
                ])),
      const ProgressNote(
          'Logged exposure describes training, not measured muscle growth.'),
    ]);
  }
}
