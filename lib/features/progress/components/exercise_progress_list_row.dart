import 'package:flutter/material.dart';
import '../../../core/localization/fitness_copy.dart';
import '../models/progress_models.dart';
import 'progress_chart.dart';
import 'progress_surface.dart';

class ExerciseProgressListRow extends StatelessWidget {
  final ProgressJson exercise;
  final VoidCallback onTap;
  const ExerciseProgressListRow(
      {super.key, required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final latest = exercise['latest'] as Map?;
    final weight = progressNumber(latest?['weight']);
    final reps = progressNumber(latest?['reps']);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final latestDate = exercise['latestDate'] as String?;
    final points =
        ProgressPoint.parse(progressRows(exercise['sparkline']), 'value');
    final loadTrend = exercise['metric'] == 'load';
    final change = progressNumber(exercise['change']);
    final target = latest == null
        ? fitnessText(context, 'No sets in this period')
        : '${fitnessText(context, 'Latest')}: ${weight != null && weight > 0 ? '${progressValue(context, weight, unit: 'kg')} × ' : ''}${progressValue(context, reps)} ${fitnessText(context, 'reps')}';
    final caption = [
      if (latestDate != null)
        progressDate(latestDate, locale,
            year: DateTime.tryParse(latestDate)?.year != DateTime.now().year),
      if (latest != null && weight == null)
        fitnessText(context, 'Weight not recorded'),
      if (latest != null && weight == 0)
        fitnessText(context, 'No external load'),
    ].join(' · ');
    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 2),
              child: LayoutBuilder(builder: (context, box) {
                final showTrend = points.length > 1 &&
                    box.maxWidth >= 280 &&
                    MediaQuery.textScalerOf(context).scale(14) < 21;
                return Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(progressTitle(exercise['name'] as String? ?? ''),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.35)),
                        const SizedBox(height: 5),
                        Text(target,
                            style: const TextStyle(
                                color: progressSilver,
                                fontSize: 12,
                                height: 1.4)),
                        if (caption.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(caption,
                                  style: const TextStyle(
                                      color: progressMuted,
                                      fontSize: 11,
                                      height: 1.35))),
                      ])),
                  if (showTrend) ...[
                    const SizedBox(width: 16),
                    SizedBox(
                        width: 76,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ExcludeSemantics(
                                  child: ProgressSparkline(
                                      points: points, color: progressSilver)),
                              const SizedBox(height: 5),
                              Text(
                                  loadTrend && change != null && change.isFinite
                                      ? '${fitnessText(context, 'Load')} ${change > 0 ? '+' : ''}${progressValue(context, change)}%'
                                      : fitnessText(context,
                                          loadTrend ? 'Load · kg' : 'Reps'),
                                  style: const TextStyle(
                                      color: progressMuted, fontSize: 10)),
                            ])),
                  ],
                ]);
              })),
        ));
  }
}
