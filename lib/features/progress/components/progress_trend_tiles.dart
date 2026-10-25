import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';

class ProgressExercisePreview extends StatelessWidget {
  final ProgressJson exercise;
  final VoidCallback onTap;
  const ProgressExercisePreview(
      {super.key, required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final latest = exercise['latest'] as Map?;
    final load = progressNumber(latest?['weight']);
    final reps = progressNumber(latest?['reps']);
    final name = exercise['name'] as String? ?? '';
    final points =
        ProgressPoint.parse(progressRows(exercise['sparkline']), 'value');
    return ProgressSurface(
        accent: progressCyan,
        padding: EdgeInsets.zero,
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: SizedBox(
                                    height: MediaQuery.textScalerOf(context)
                                        .scale(34),
                                    child: Text(
                                        name.isEmpty
                                            ? name
                                            : '${name[0].toUpperCase()}${name.substring(1)}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            height: 1.3)))),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right,
                                color: progressMuted, size: 16),
                          ]),
                      const SizedBox(height: 10),
                      Text.rich(
                          TextSpan(children: [
                            TextSpan(
                                text: progressValue(context,
                                    load != null && load > 0 ? load : reps)),
                            TextSpan(
                                text: load != null && load > 0
                                    ? ' kg'
                                    : ' ${fitnessText(context, 'reps')}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: progressMuted,
                                    letterSpacing: 0)),
                          ]),
                          style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.8)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Expanded(
                            child: Text(
                                load != null && load > 0
                                    ? '× ${progressValue(context, reps)} ${fitnessText(context, 'reps')}'
                                    : fitnessText(
                                        context,
                                        latest == null
                                            ? 'No sets in this period'
                                            : load == null
                                                ? 'Weight not recorded'
                                                : 'No external load'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: progressMuted))),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: double.infinity,
                          height: MediaQuery.textScalerOf(context).scale(38),
                          child: points.length < 2
                              ? Text(
                                  fitnessText(context,
                                      'More workouts will reveal your trend.'),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: progressMuted,
                                      height: 1.4))
                              : ProgressSparkline(points: points)),
                    ]))));
  }
}

class ProgressMetricPreview extends StatelessWidget {
  final String title, unit, caption;
  final List<ProgressPoint> points;
  final Color color;
  final bool average;
  final VoidCallback onTap;
  const ProgressMetricPreview({
    super.key,
    required this.title,
    required this.unit,
    required this.points,
    required this.onTap,
    this.caption = 'Latest reading',
    this.color = progressCyan,
    this.average = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = points.isEmpty
        ? null
        : average
            ? points.fold<double>(0, (sum, point) => sum + point.value) /
                points.length
            : points.last.value;
    return LayoutBuilder(
        builder: (context, box) => ProgressSurface(
            accent: color,
            padding: EdgeInsets.zero,
            child: InkWell(
                onTap: onTap,
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(fitnessText(context, title),
                                style: const TextStyle(
                                    fontSize: 12, color: progressMuted)),
                            const SizedBox(height: 7),
                            ProgressValueText(
                                progressValue(context, value, unit: unit),
                                color: progressSilver,
                                size: 27),
                            const SizedBox(height: 5),
                            Text(fitnessText(context, caption),
                                style: const TextStyle(
                                    fontSize: 10, color: progressMuted)),
                            if (points.length > 1 && box.maxWidth < 260) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                  height: 32,
                                  width: double.infinity,
                                  child: ProgressSparkline(
                                      points: points,
                                      color: color,
                                      daily: average)),
                            ],
                          ])),
                      if (points.length > 1 && box.maxWidth >= 260)
                        SizedBox(
                            width: 88,
                            height: 42,
                            child: ProgressSparkline(
                                points: points, color: color, daily: average)),
                      const SizedBox(width: 10),
                      const Icon(Icons.chevron_right,
                          color: progressMuted, size: 16),
                    ])))));
  }
}
