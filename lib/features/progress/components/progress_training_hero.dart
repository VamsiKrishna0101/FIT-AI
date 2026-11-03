import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';
import 'progress_weekly_bars.dart';

/// The headline, comparison and chart all count completed workouts.
class ProgressTrainingHero extends StatelessWidget {
  final ProgressJson summary;
  final List<ProgressJson> weeks;
  final String? rangeLabel, previousRangeLabel;
  final String period;
  final VoidCallback onOpen;

  const ProgressTrainingHero({
    super.key,
    required this.summary,
    required this.weeks,
    required this.onOpen,
    this.rangeLabel,
    this.previousRangeLabel,
    this.period = '4w',
  });

  @override
  Widget build(BuildContext context) {
    final workouts = progressNumber(summary['workouts']) ?? 0;
    final sets = progressNumber(summary['sets']) ?? 0;
    final change = progressNumber(summary['workoutChange']);
    final canCompare = summary['hasPreviousTraining'] == true ||
        (progressNumber(summary['previousWorkouts']) ?? 0) > 0;
    final points = ProgressPoint.parse(weeks, 'workouts');
    final title = switch (period) {
      '4w' => 'Your last 4 weeks',
      '3m' => 'Your last 3 months',
      '1y' => 'Your last year',
      'all' => 'Your training so far',
      _ => 'Your selected dates',
    };

    return ProgressSurface(
      hero: true,
      padding: EdgeInsets.zero,
      child: InkWell(
        key: const ValueKey('progress-open-activity'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fitnessText(context, title),
                style: const TextStyle(
                    fontSize: 13, color: progressMuted, height: 1.4)),
            const SizedBox(height: 10),
            Text(
                fitnessText(
                    context,
                    workouts == 1
                        ? '{count} workout completed'
                        : '{count} workouts completed',
                    values: {
                      'count': progressValue(context, workouts, digits: 0)
                    }),
                style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.6,
                    height: 1.2,
                    color: progressSilver)),
            const SizedBox(height: 8),
            if (canCompare && change != null && change.isFinite) ...[
              Text(
                  fitnessText(
                      context,
                      change.abs() == 1
                          ? '{change} workout vs previous period'
                          : '{change} workouts vs previous period',
                      values: {
                        'change':
                            '${change > 0 ? '+' : ''}${progressValue(context, change, digits: 0)}'
                      }),
                  style: const TextStyle(
                      color: progressSilver, fontSize: 12, height: 1.4)),
              if (previousRangeLabel != null) ...[
                const SizedBox(height: 3),
                Text(previousRangeLabel!,
                    style: const TextStyle(
                        color: progressMuted, fontSize: 11, height: 1.4)),
              ],
            ] else if (workouts == 0 && sets > 0)
              Text(
                  fitnessText(context,
                      'Your sets are saved. Finish a workout to add it here.'),
                  style: const TextStyle(
                      color: progressMuted, fontSize: 12, height: 1.5))
            else if (period != 'all')
              Text(
                  fitnessText(context,
                      'Keep logging to build your comparison over time.'),
                  style: const TextStyle(
                      color: progressMuted, fontSize: 12, height: 1.5)),
            if (points.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(fitnessText(context, 'Workouts per week'),
                  style: const TextStyle(
                      fontSize: 12, color: progressMuted, height: 1.4)),
              const SizedBox(height: 12),
              if (points.length <= 6)
                ProgressWeeklyBars(
                    points: points,
                    metric: 'Workouts',
                    color: progressSilver,
                    compact: true)
              else
                ProgressChart(
                    points: points,
                    bars: true,
                    digits: 0,
                    compactHeader: true,
                    color: progressSilver,
                    height: 72),
              if (weeks.any((week) => week['partial'] == true)) ...[
                const SizedBox(height: 10),
                Text(
                    fitnessText(
                        context, 'Edge weeks include only the selected dates.'),
                    style: const TextStyle(
                        color: progressMuted, fontSize: 11, height: 1.4)),
              ],
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: Text(fitnessText(context, 'Training details'),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: progressSilver))),
              const Icon(CupertinoIcons.chevron_right,
                  size: 12, color: progressMuted),
            ]),
          ]),
        ),
      ),
    );
  }
}
