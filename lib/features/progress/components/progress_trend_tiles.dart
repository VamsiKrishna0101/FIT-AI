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
    final change = progressNumber(exercise['change']);
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
                                        .scale(38),
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
                      const SizedBox(height: 16),
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
                              fontSize: 27,
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
                                            : 'No external load'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: progressMuted))),
                        if (change != null)
                          Text(
                              '${change > 0 ? '+' : ''}${progressValue(context, change)}%',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: progressCyan,
                                  fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 17),
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
    return ProgressSurface(
        padding: EdgeInsets.zero,
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(fitnessText(context, title),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500))),
                        const Icon(Icons.chevron_right,
                            color: progressMuted, size: 16),
                      ]),
                      const SizedBox(height: 15),
                      Text.rich(
                          TextSpan(children: [
                            TextSpan(text: progressValue(context, value)),
                            if (value != null)
                              TextSpan(
                                  text: ' ${fitnessText(context, unit)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: progressMuted,
                                      letterSpacing: 0)),
                          ]),
                          style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.8)),
                      const SizedBox(height: 5),
                      SizedBox(
                          height: MediaQuery.textScalerOf(context).scale(34),
                          child: Text(fitnessText(context, caption),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: progressMuted))),
                      const SizedBox(height: 18),
                      SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: points.length < 2
                              ? Text(
                                  fitnessText(context,
                                      'More readings will reveal your trend.'),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: progressMuted,
                                      height: 1.4))
                              : ProgressSparkline(
                                  points: points,
                                  color: color,
                                  daily: average)),
                    ]))));
  }
}
